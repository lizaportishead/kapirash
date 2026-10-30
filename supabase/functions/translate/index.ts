// Лимит запросов считается в базе (таблица rate_hits, supabase/rate_limit.sql), поэтому общий для всех копий функции.
// Если база не ответила, запрос пропускаем: лучше лишний запрос, чем сломанная функция.
async function hit(key: string, limit: number, windowSec: number): Promise<boolean> {
  const k = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  try {
    const r = await fetch(`${Deno.env.get("SUPABASE_URL")}/rest/v1/rpc/rate_check`, {
      method: "POST",
      signal: AbortSignal.timeout(3000),
      headers: { apikey: k, Authorization: `Bearer ${k}`, "content-type": "application/json" },
      body: JSON.stringify({ p_key: key, p_limit: limit, p_window_seconds: windowSec }),
    });
    if (!r.ok) {
      console.error("rate_check", r.status, (await r.text()).slice(0, 200));
      return true;
    }
    return (await r.json()) === true;
  } catch (e) {
    console.error("rate_check", e);
    return true;
  }
}

/** true, если запрос можно пропустить: perIp запросов с одного адреса и total со всех за windowSec секунд. */
async function allow(req: Request, name: string, perIp: number, windowSec: number, total: number): Promise<boolean> {
  const h = req.headers;
  const ip = (h.get("cf-connecting-ip") ?? h.get("x-forwarded-for")?.split(",")[0] ?? "unknown").trim();
  return (await hit(`${name}:ip:${ip}`, perIp, windowSec)) && (await hit(`${name}:all`, total, windowSec));
}

const tooMany = (cors: Record<string, string>) =>
  new Response(JSON.stringify({ error: "rate limit" }), {
    status: 429,
    headers: { ...cors, "Content-Type": "application/json", "Retry-After": "60" },
  });

// Перевод выделенной фразы с учётом предложения: GET /functions/v1/translate?p=<фраза>&s=<предложение>&to=ru|en.
// Отвечает {"phrase": "...", "sentence": "..."}. Ключ Google AI Studio лежит в секрете GEMINI_API_KEY.
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" };
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  // Платный ключ Gemini: 30 переводов в минуту с адреса и 600 в минуту на всех.
  if (!(await allow(req, "translate", 30, 60, 600))) return tooMany(cors);
  const q = new URL(req.url).searchParams;
  const phrase = (q.get("p") ?? "").trim().slice(0, 200);
  const sentence = (q.get("s") ?? "").trim().slice(0, 500);
  const lang = q.get("to") === "en" ? "English" : "Russian";
  if (!phrase || !sentence) return json({ error: "p and s required" }, 400);

  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${Deno.env.get("GEMINI_API_KEY") ?? ""}`,
    {
      method: "POST",
      signal: AbortSignal.timeout(9000),
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{
            text: `You translate Serbian (ekavian) for a language learner. Given a sentence and a phrase taken from it, ` +
              `translate the phrase into ${lang} as it is used in THIS sentence (idioms and fixed expressions by meaning, not word by word), ` +
              `keeping it short and in a form that fits the phrase's own grammar. Also translate the whole sentence naturally. ` +
              `Reply with JSON only: {"phrase": "...", "sentence": "..."}.`,
          }],
        },
        contents: [{ role: "user", parts: [{ text: `Sentence: ${sentence}\nPhrase: ${phrase}` }] }],
        generationConfig: { responseMimeType: "application/json", maxOutputTokens: 400, thinkingConfig: { thinkingLevel: "low" } },
      }),
    },
  );
  if (!r.ok) {
    const detail = (await r.text()).slice(0, 300);
    console.error("gemini", r.status, detail);
    return json({ error: "llm" }, 502);
  }
  try {
    const text = (await r.json()).candidates[0].content.parts[0].text as string;
    const out = JSON.parse(text.slice(text.indexOf("{"), text.lastIndexOf("}") + 1));
    return json({ phrase: String(out.phrase), sentence: String(out.sentence) }, 200);
  } catch (_) {
    return json({ error: "parse" }, 502);
  }
});
