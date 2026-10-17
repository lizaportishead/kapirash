"""Воркер очереди своих роликов: заявка из video_requests -> аудио -> текст -> перевод и словарик -> бакет subs.

Переменные окружения: SUPABASE_URL, SUPABASE_SERVICE_KEY, ANTHROPIC_API_KEY,
YT_COOKIES_FILE (необязательно: cookies YouTube, если он просит подтвердить, что вы не бот).
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import time

import anthropic
import requests

URL = os.environ["SUPABASE_URL"].rstrip("/")
KEY = os.environ["SUPABASE_SERVICE_KEY"]
MODEL = os.environ.get("CLAUDE_MODEL", "claude-sonnet-5-5")
H = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}
CHUNK = 40  # реплик за один запрос к Claude
WORD = re.compile(r"[^\W_]+(?:['\-][^\W_]+)*", re.UNICODE)


def rest(method, path, **kw):
    r = requests.request(method, f"{URL}/rest/v1/{path}", headers={**H, "Content-Type": "application/json", **kw.pop("headers", {})}, timeout=60, **kw)
    r.raise_for_status()
    return r.json() if r.text else None


def claim():
    """Берёт самую старую заявку; PATCH по условию status=queued не даст двум воркерам взять одну."""
    rows = rest("GET", "video_requests?status=eq.queued&order=created_at.asc&limit=1")
    if not rows:
        return None
    got = rest("PATCH", f"video_requests?id=eq.{rows[0]['id']}&status=eq.queued",
               json={"status": "processing"}, headers={"Prefer": "return=representation"})
    return got[0] if got else None


def finish(vid, status, error=None):
    rest("PATCH", f"video_requests?id=eq.{vid}", json={"status": status, "error": error, "finished_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())})


def upload(name, data, ctype):
    r = requests.post(f"{URL}/storage/v1/object/subs/{name}", data=data.encode(), timeout=120,
                      headers={**H, "Content-Type": ctype + "; charset=utf-8", "x-upsert": "true"})
    r.raise_for_status()


def download_audio(vid, tmp):
    cmd = ["yt-dlp", "-f", "140/bestaudio", "--no-playlist", "--js-runtimes", "node", "-o", f"{tmp}/audio.%(ext)s"]
    if os.environ.get("YT_COOKIES_FILE"):
        cmd += ["--cookies", os.environ["YT_COOKIES_FILE"]]
    subprocess.run(cmd + [f"https://www.youtube.com/watch?v={vid}"], check=True)
    return next(os.path.join(tmp, f) for f in os.listdir(tmp) if f.startswith("audio."))


_model = None


def transcribe(path, title, channel):
    """Список (начало, конец, текст). Длинные сегменты режем по словам, чтобы реплики были короткими."""
    global _model
    from faster_whisper import WhisperModel
    _model = _model or WhisperModel("large-v3-turbo", device="cpu", compute_type="int8")
    segs, _ = _model.transcribe(path, language="sr", word_timestamps=True, vad_filter=True,
                                initial_prompt=f"Govor na srpskom jeziku. Kanal {channel}. {title}.")
    cues = []
    for s in segs:
        cur = []
        for w in s.words or []:
            if cur and (w.end - cur[0].start > 6.5 or sum(len(x.word) for x in cur) > 85):
                cues.append((cur[0].start, cur[-1].end, "".join(x.word for x in cur).strip()))
                cur = []
            cur.append(w)
        if cur:
            cues.append((cur[0].start, cur[-1].end, "".join(x.word for x in cur).strip()))
    return [c for c in cues if c[2]]


def ask(client, prompt):
    msg = client.messages.create(model=MODEL, max_tokens=16000, messages=[{"role": "user", "content": prompt}])
    text = msg.content[0].text
    return json.loads(text[text.index("{"): text.rindex("}") + 1])


RULES = """Ты помогаешь делать субтитры для изучающих сербский (носитель русского).
Верни ТОЛЬКО JSON без пояснений.
- sr: исправь распознавание речи (опечатки, склеенные и разорванные слова, икавизмы и иекавизмы, если это артефакт), \
запиши ЛАТИНИЦЕЙ, не меняя смысл и не пересказывая. Если реплика — мусор или тишина, поставь пустую строку.
- ru: естественный перевод реплики на русский.
- dict: для КАЖДОГО слова из исправленных sr (в нижнем регистре, как в тексте, включая числа и слова с апострофом) \
запись "слово": ["перевод слова в этой форме", "начальная форма и пометка: падеж/время/род, если форма не начальная"]."""


def translate(client, cues, title, channel):
    out, dic = [], {}
    for i in range(0, len(cues), CHUNK):
        part = cues[i:i + CHUNK]
        data = ask(client, f"{RULES}\n\nРолик «{title}», канал {channel}.\nФормат ответа: "
                   '{"cues":[{"i":0,"sr":"...","ru":"..."}],"dict":{"slovo":["перевод","lemma — пометка"]}}\n\n'
                   + json.dumps([{"i": k, "t": c[2]} for k, c in enumerate(part)], ensure_ascii=False))
        by = {c["i"]: c for c in data["cues"]}
        for k, c in enumerate(part):
            r = by.get(k, {})
            out.append((c[0], c[1], (r.get("sr") or "").strip(), (r.get("ru") or "").strip()))
        for w, v in data.get("dict", {}).items():
            dic.setdefault(w.lower(), v)
    out = [o for o in out if o[2]]
    # Слова, которым Claude не дал записи, докидываем отдельным запросом.
    missing = sorted({w.lower() for o in out for w in WORD.findall(o[2])} - dic.keys())
    for i in range(0, len(missing), 150):
        data = ask(client, f'{RULES}\n\nДай dict только для этих слов. Формат ответа: {{"dict":{{"slovo":["перевод","пометка"]}}}}\n\n'
                   + json.dumps(missing[i:i + 150], ensure_ascii=False))
        for w, v in data.get("dict", {}).items():
            dic.setdefault(w.lower(), v)
    return out, dic


def ts(x):
    ms = int(round(x * 1000))
    return f"{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d}.{ms % 1000:03d}"


def vtt(cues, idx):
    body = "".join(f"{n}\n{ts(c[0])} --> {ts(c[1])}\n{c[idx]}\n\n" for n, c in enumerate(cues, 1))
    return "WEBVTT\n\n" + body


def process(job):
    vid = job["id"]
    client = anthropic.Anthropic()
    with tempfile.TemporaryDirectory() as tmp:
        raw = transcribe(download_audio(vid, tmp), job["title"], job["channel"])
    if len(raw) < 3:
        raise RuntimeError("В ролике не нашли речи на сербском")
    cues, dic = translate(client, raw, job["title"], job["channel"])
    upload(f"{vid}.sr.vtt", vtt(cues, 2), "text/vtt")
    upload(f"{vid}.ru.vtt", vtt(cues, 3), "text/vtt")
    upload(f"{vid}.dict.json", json.dumps(dic, ensure_ascii=False, indent=0), "application/json")


def main():
    deadline = time.time() + float(os.environ.get("MAX_SECONDS", 4 * 3600))
    while time.time() < deadline:
        job = claim()
        if not job:
            return
        print(f"== {job['id']} {job['title']}", flush=True)
        try:
            process(job)
            finish(job["id"], "ready")
        except Exception as e:  # noqa: BLE001 — любая ошибка должна дойти до приложения
            print("FAILED:", repr(e), file=sys.stderr, flush=True)
            finish(job["id"], "failed", str(e)[:300])


if __name__ == "__main__":
    main()
