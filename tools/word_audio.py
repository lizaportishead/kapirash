#!/usr/bin/env python3
"""Озвучка слов для карточек: сербский нейроголос Microsoft (sr-RS) -> mp3 -> бакет `tts` в Supabase.

    pip install edge-tts
    python3 tools/word_audio.py gen  work/tts          # собрать слова из app/assets/*.dict.json и сгенерировать mp3
    SUPABASE_SERVICE_KEY=... python3 tools/word_audio.py up work/tts   # залить недостающие файлы

Имя файла = word_file() ниже; приложение (app/lib/speak.dart) строит то же имя из латиницы слова.
"""
import asyncio, glob, json, os, re, sys, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
URL = "https://ynwpzcoayepczgtayimr.supabase.co"
VOICE = "sr-RS-NicholasNeural"
_FOLD = {"č": "_c", "ć": "_k", "š": "_s", "ž": "_z", "đ": "_d"}
_L2C = {"lj": "љ", "nj": "њ", "dž": "џ", "a": "а", "b": "б", "v": "в", "g": "г", "d": "д", "đ": "ђ", "e": "е",
        "ž": "ж", "z": "з", "i": "и", "j": "ј", "k": "к", "l": "л", "m": "м", "n": "н", "o": "о", "p": "п",
        "r": "р", "s": "с", "t": "т", "ć": "ћ", "u": "у", "f": "ф", "h": "х", "c": "ц", "č": "ч", "š": "ш"}


def word_file(lat):
    """latin word -> storage file name, or None when it is not a plain word."""
    out = "".join(_FOLD.get(ch, ch) for ch in lat.lower())
    return out + ".mp3" if re.fullmatch(r"[a-z_]+", out) else None


def to_cyr(lat):
    return re.sub(r"lj|nj|dž|.", lambda m: _L2C.get(m[0], m[0]), lat.lower())


def collect():
    words = set()
    for f in glob.glob(os.path.join(ROOT, "app/assets/*.dict.json")):
        if ".en." in f:
            continue
        for k, v in json.load(open(f, encoding="utf-8")).items():
            words.add(k.lower())
            m = re.match(r"^([^\W\d_]+(?:-[^\W\d_]+)?)(?:\s*\(se\))?\s*(?:$|[;—–,:(])", v[1] if len(v) > 1 else "")
            if m and re.match(r"^[a-zčćžšđ]", m[1].lower()):
                words.add(m[1].lower())
    return sorted(w for w in words if word_file(w))


async def gen(out):
    import edge_tts
    os.makedirs(out, exist_ok=True)
    todo = [w for w in collect() if not os.path.exists(os.path.join(out, word_file(w)))]
    print(len(todo), "to generate")
    sem, done = asyncio.Semaphore(40), [0]

    async def one(w):
        async with sem:
            for attempt in range(4):
                try:
                    await edge_tts.Communicate(to_cyr(w), VOICE, rate="-10%").save(os.path.join(out, word_file(w)))
                    break
                except Exception as e:
                    if attempt == 3:
                        print("FAIL", w, e)
                    await asyncio.sleep(1 + attempt)
            done[0] += 1
            if done[0] % 500 == 0:
                print(done[0], flush=True)

    await asyncio.gather(*(one(w) for w in todo))


def up(folder):
    key = os.environ["SUPABASE_SERVICE_KEY"]
    h = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "audio/mpeg", "x-upsert": "true"}

    def put(name):
        req = urllib.request.Request(f"{URL}/storage/v1/object/tts/{name}", data=open(os.path.join(folder, name), "rb").read(),
                                     method="POST", headers=h)
        for _ in range(3):
            try:
                urllib.request.urlopen(req).read()
                return 1
            except urllib.error.HTTPError as e:
                if e.code == 400 and b"Duplicate" in e.read():
                    return 1
            except Exception:
                pass
        print("FAIL", name)
        return 0

    names = sorted(n for n in os.listdir(folder) if n.endswith(".mp3"))
    with ThreadPoolExecutor(12) as ex:
        n = sum(ex.map(put, names))
    print("uploaded", n, "of", len(names))


if __name__ == "__main__":
    {"gen": lambda: asyncio.run(gen(sys.argv[2])), "up": lambda: up(sys.argv[2])}[sys.argv[1]]()
