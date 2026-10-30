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

// Обратная связь из приложения: POST /functions/v1/feedback {"text": "...", "contact": "...", "from": "...", "lang": "ru"}
// Пересылает сообщение в Telegram. Секреты: TELEGRAM_BOT_TOKEN (от @BotFather) и TELEGRAM_CHAT_ID (твой id, см. @userinfobot).
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" };
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  // Не больше 3 сообщений в час с адреса и 100 в час всего.
  if (!(await allow(req, "feedback", 3, 3600, 100))) return tooMany(cors);
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad json" }, 400);
  }
  const s = (k: string, n: number) => String(body[k] ?? "").trim().slice(0, n);
  const text = s("text", 2000);
  if (text.length < 3) return json({ error: "text required" }, 400);

  const msg = [
    "💬 Kapiras: отзыв",
    text,
    "",
    `Контакт: ${s("contact", 200) || "—"}`,
    `Аккаунт: ${s("from", 200) || "—"}`,
    `Язык: ${s("lang", 5) || "—"} · ${s("platform", 30) || "—"}`,
  ].join("\n");

  const r = await fetch(`https://api.telegram.org/bot${Deno.env.get("TELEGRAM_BOT_TOKEN") ?? ""}/sendMessage`, {
    method: "POST",
    signal: AbortSignal.timeout(9000),
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ chat_id: Deno.env.get("TELEGRAM_CHAT_ID") ?? "", text: msg }),
  });
  if (!r.ok) {
    console.error("telegram", r.status, (await r.text()).slice(0, 300));
    return json({ error: "telegram" }, 502);
  }
  return json({ ok: true });
});
