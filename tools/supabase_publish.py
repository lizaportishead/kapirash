#!/usr/bin/env python3
"""Публикует партию роликов в Supabase: строки в creators/videos + файлы в бакет subs.

Ключ (secret / service_role) берётся из переменной SUPABASE_SERVICE_KEY, в репозиторий его не кладём:

    SUPABASE_SERVICE_KEY=sb_secret_... python3 tools/supabase_publish.py supabase/upload_2026-10-19 supabase/batch_2026-10-19.sql

Первый аргумент — папка с <id>.sr.vtt / <id>.ru.vtt / <id>.dict.json, второй — SQL партии
(строки читаются из него же, чтобы список не дублировался).
"""
import json, os, re, sys, urllib.request, urllib.error

URL = "https://ynwpzcoayepczgtayimr.supabase.co"
KEY = os.environ["SUPABASE_SERVICE_KEY"]
H = {"apikey": KEY, "Authorization": f"Bearer {KEY}"}


def call(method, path, body=None, headers=None, raw=False):
    h = dict(H, **(headers or {}))
    data = body if raw else (json.dumps(body).encode() if body is not None else None)
    if data is not None and not raw:
        h["Content-Type"] = "application/json"
    req = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path}: {e.code} {e.read().decode()[:300]}")


folder, sql = sys.argv[1], open(sys.argv[2], encoding="utf-8").read()
tuple_re = r"\(\s*((?:'(?:[^']|'')*'|null)(?:\s*,\s*(?:'(?:[^']|'')*'|null))*)\s*\)"


def rows(table):
    block = re.search(rf"insert into public\.{table}.*?values(.*?)on conflict", sql, re.S).group(1)
    out = []
    for m in re.finditer(tuple_re, block):
        vals = re.findall(r"'((?:[^']|'')*)'|(null)", m.group(1))
        out.append([None if n else v.replace("''", "'") for v, n in vals])
    return out


up = {"Prefer": "resolution=ignore-duplicates,return=minimal"}
creators = [dict(zip(["name", "handle", "avatar_id"], r)) for r in rows("creators")]
videos = [dict(zip(["id", "title", "channel", "topic", "level", "duration"], r)) for r in rows("videos")]
print("creators", call("POST", "/rest/v1/creators?on_conflict=name", creators, up))
print("videos", call("POST", "/rest/v1/videos?on_conflict=id", videos, up))

for name in sorted(os.listdir(folder)):
    if name.startswith("."):
        continue
    ctype = "application/json" if name.endswith(".json") else "text/vtt"
    with open(os.path.join(folder, name), "rb") as f:
        code = call("POST", f"/storage/v1/object/subs/{name}", f.read(),
                    {"Content-Type": ctype, "x-upsert": "true"}, raw=True)
    print("upload", name, code)
