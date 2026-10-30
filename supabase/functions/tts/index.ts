// Озвучка слова сербским голосом: GET /functions/v1/tts?w=<слово кириллицей>.
// Берёт звук у нейроголоса Microsoft (read-aloud), кладёт в бакет `tts` и дальше отдаёт из него:
// в хранилище оказываются только слова, которые реально нажимали.
import { createClient } from "jsr:@supabase/supabase-js@2";

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

const TOKEN = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
const VOICE = "sr-RS-NicholasNeural";
const VERSION = "143.0.3650.75";
const FOLD: Record<string, string> = { "č": "_c", "ć": "_k", "š": "_s", "ž": "_z", "đ": "_d" };
const L2C: Record<string, string> = {
  lj: "љ", nj: "њ", "dž": "џ", a: "а", b: "б", v: "в", g: "г", d: "д", "đ": "ђ", e: "е", "ž": "ж", z: "з",
  i: "и", j: "ј", k: "к", l: "л", m: "м", n: "н", o: "о", p: "п", r: "р", s: "с", "ć": "ћ", t: "т", u: "у",
  f: "ф", h: "х", c: "ц", "č": "ч", "š": "ш",
};

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" };
const hex = (b: ArrayBuffer) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("").toUpperCase();
const toCyr = (s: string) => s.replace(/lj|nj|dž|./g, (m) => L2C[m] ?? m);

async function secMsGec() {
  let ticks = Math.floor(Date.now() / 1000) + 11644473600;
  ticks -= ticks % 300;
  const str = `${BigInt(ticks) * 10000000n}${TOKEN}`;
  return hex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(str)));
}

function synth(text: string): Promise<Uint8Array> {
  return new Promise(async (resolve, reject) => {
    const id = crypto.randomUUID().replaceAll("-", "");
    const url = `wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=${TOKEN}` +
      `&Sec-MS-GEC=${await secMsGec()}&Sec-MS-GEC-Version=1-${VERSION}&ConnectionId=${id}`;
    // deno-lint-ignore no-explicit-any
    const ws = new (WebSocket as any)(url, {
      headers: {
        "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
        "User-Agent": `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${VERSION.split(".")[0]}.0.0.0 Safari/537.36 Edg/${VERSION.split(".")[0]}.0.0.0`,
      },
    });
    ws.binaryType = "arraybuffer";
    const chunks: Uint8Array[] = [];
    const timer = setTimeout(() => { ws.close(); reject(new Error("timeout")); }, 8000);
    const ts = new Date().toUTCString();
    ws.onopen = () => {
      ws.send(`X-Timestamp:${ts}\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n` +
        `{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}`);
      const esc = text.replace(/[<>&]/g, "");
      ws.send(`X-RequestId:${id}\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:${ts}Z\r\nPath:ssml\r\n\r\n` +
        `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='sr-RS'><voice name='${VOICE}'><prosody pitch='+0Hz' rate='-10%' volume='+0%'>${esc}</prosody></voice></speak>`);
    };
    ws.onmessage = (e: MessageEvent) => {
      if (typeof e.data === "string") {
        if (e.data.includes("Path:turn.end")) {
          clearTimeout(timer);
          ws.close();
          const out = new Uint8Array(chunks.reduce((n, c) => n + c.length, 0));
          let o = 0;
          for (const c of chunks) { out.set(c, o); o += c.length; }
          out.length ? resolve(out) : reject(new Error("empty"));
        }
      } else {
        const b = new Uint8Array(e.data as ArrayBuffer);
        const headLen = (b[0] << 8) | b[1];
        if (new TextDecoder().decode(b.slice(2, 2 + headLen)).includes("Path:audio")) chunks.push(b.slice(2 + headLen));
      }
    };
    ws.onerror = () => { clearTimeout(timer); reject(new Error("ws error")); };
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  const lat = (new URL(req.url).searchParams.get("w") ?? "").toLowerCase().trim();
  const name = [...lat].map((c) => FOLD[c] ?? c).join("");
  if (!/^[a-z_]{1,30}$/.test(name)) return new Response("bad word", { status: 400, headers: cors });

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const file = `${name}.mp3`;
  const pub = db.storage.from("tts").getPublicUrl(file).data.publicUrl;
  const hit = await fetch(pub);
  if (hit.ok) return new Response(hit.body, { headers: { ...cors, "Content-Type": "audio/mpeg", "Cache-Control": "public, max-age=31536000" } });
  await hit.body?.cancel();

  // Новые слова озвучиваем не чаще 20 в минуту с адреса и 120 в минуту всего; готовые отдаются без лимита.
  if (!(await allow(req, "tts", 20, 60, 120))) return tooMany(cors);
  try {
    const mp3 = await synth(toCyr(lat));
    await db.storage.from("tts").upload(file, mp3, { contentType: "audio/mpeg", upsert: true });
    return new Response(mp3, { headers: { ...cors, "Content-Type": "audio/mpeg", "Cache-Control": "public, max-age=31536000" } });
  } catch (e) {
    console.error("tts", e);
    return new Response("tts failed", { status: 502, headers: cors });
  }
});
