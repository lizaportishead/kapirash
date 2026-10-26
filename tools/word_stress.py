#!/usr/bin/env python3
"""Ударения для карточек: тянет акцентированные формы из en.wiktionary (раздел Serbo-Croatian) -> app/assets/stress.json.

    python3 tools/word_stress.py [out.json]

Берутся все слова с тональными знаками со страницы слова (заголовок, таблица склонения), поэтому формы
получают ударение и со страницы леммы. Знак приводится к одному острому ударению над ударной гласной,
долгота-макрон отбрасывается. Слова без данных в файл не попадают, односложные тоже.
"""
import json, os, re, sys, time, unicodedata, urllib.parse, urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from word_audio import collect

API = "https://en.wiktionary.org/w/api.php"
STRESS = {"̀", "́", "̏", "̑"}
TOKEN = re.compile(r"[^\W\d_]+", re.U)


def norm(token):
    """accented token -> (plain, with_acute) or None when it carries no stress."""
    plain, out, ok, base = "", "", False, ""
    for ch in unicodedata.normalize("NFD", token.lower()):
        if not unicodedata.combining(ch):
            plain += ch
            out += ch
            base = ch
        elif base in "aeiour":
            # на гласной (и слоговом r): остриё/гравис/двойной гравис/инвертированная бреве = ударение, макрон и прочее отбрасываем
            if ch in STRESS and not ok:
                out += "\u0301"
                ok = True
        else:
            plain += ch  # гачек над č, š, ž и острый над ć — часть буквы
            out += ch
    return (unicodedata.normalize("NFC", plain), unicodedata.normalize("NFC", out)) if ok else None


def fetch(titles):
    q = urllib.parse.urlencode({"action": "query", "prop": "revisions", "rvprop": "content", "rvslots": "main",
                                "format": "json", "formatversion": 2, "titles": "|".join(titles)})
    req = urllib.request.Request(f"{API}?{q}", headers={"User-Agent": "kapiras-player stress builder (ilovekurm@gmail.com)"})
    for i in range(4):
        try:
            return json.load(urllib.request.urlopen(req, timeout=60))["query"]["pages"]
        except Exception as e:
            time.sleep(2 + i * 3)
    return []


def section(text):
    m = re.search(r"==Serbo-Croatian==(.*?)(?=\n==[^=]|\Z)", text, re.S)
    body = m.group(1) if m else ""
    body = re.sub(r"===+Etymology[^=\n]*===+.*?(?=\n===|\Z)", "", body, flags=re.S)  # реконструкции вроде *wódr̥
    return re.sub(r"\{\{(?:inh\+?|m|cog|der|root|etymon|bor)\|[^}]*\}\}", "", body)


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "../app/assets/stress.json")
    words = collect()
    found = {}
    for i in range(0, len(words), 50):
        for p in fetch(words[i:i + 50]):
            text = (p.get("revisions") or [{}])[0].get("slots", {}).get("main", {}).get("content", "")
            for tok in TOKEN.findall(section(text)):
                r = norm(tok)
                if r and r[0] not in found:
                    found[r[0]] = r[1]
        if i % 1000 == 0:
            print(i, len(found), flush=True)
        time.sleep(0.3)
    vow = re.compile(r"[aeiou]|(?<![aeiou])r(?![aeiou])")
    res = {w: a for w, a in sorted(found.items()) if len(vow.findall(w)) > 1}
    json.dump(res, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    have = sum(1 for w in words if w in res)
    print(len(res), "stressed forms;", have, "of", len(words), "dictionary words covered")


main()
