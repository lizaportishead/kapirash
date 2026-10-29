// Обратная связь из приложения: POST /functions/v1/feedback {"text": "...", "contact": "...", "from": "...", "lang": "ru"}
// Пересылает сообщение в Telegram. Секреты: TELEGRAM_BOT_TOKEN (от @BotFather) и TELEGRAM_CHAT_ID (твой id, см. @userinfobot).
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" };
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
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
