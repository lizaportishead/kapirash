#!/usr/bin/env python3
"""Разбор очереди своих рассказов (таблица my_stories в Supabase). Ключ — из tools/.env.local.

    process.py pull [--dir work]   — берёт заявки queued, пишет <dir>/<id>.txt и <dir>/<id>.todo.json:
                                     слова, которых нет ни в одном словаре приложения (их переводит Claude)
    process.py push <id> <fill.json> [--dir work]
                                   — fill.json = {"слово": ["перевод", "пометка", "translation", "note"]};
                                     собирает словарь (старые записи + новые), кладёт в строку, status=ready
    process.py fail <id> "причина"

Словарь — как у встроенных рассказов: ключ — слово в нижнем регистре без знаков, значение — [перевод, пометка].
"""
import glob, json, os, re, sys, urllib.request, urllib.error

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
URL = 'https://ynwpzcoayepczgtayimr.supabase.co'


def key():
    for l in open(f'{ROOT}/tools/.env.local'):
        if l.startswith('SUPABASE_SECRET_KEY='):
            return l.split('=', 1)[1].strip()
    sys.exit('нет SUPABASE_SECRET_KEY в tools/.env.local')


def call(method, path, body=None):
    k = key()
    h = {'apikey': k, 'Authorization': f'Bearer {k}', 'Content-Type': 'application/json', 'Prefer': 'return=minimal'}
    req = urllib.request.Request(URL + '/rest/v1/' + path, method=method, headers=h,
                                 data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req) as r:
            t = r.read().decode()
            return json.loads(t) if t else None
    except urllib.error.HTTPError as e:
        sys.exit(f'{method} {path}: {e.code} {e.read().decode()[:300]}')


cw = lambda w: re.sub(r"[^\w'-]", '', w).replace('_', '')


def known(en):
    d = {}
    for f in sorted(glob.glob(f'{ROOT}/app/assets/*.dict.{"en." if en else ""}json')):
        if not en and f.endswith('.en.json'):
            continue
        d.update(json.load(open(f, encoding='utf-8')))
    return d


def words(text):
    return sorted({cw(w).lower() for w in text.split() if cw(w)})


def main():
    a = sys.argv[1:]
    out = a[a.index('--dir') + 1] if '--dir' in a else 'work'
    os.makedirs(out, exist_ok=True)
    if a[0] == 'pull':
        ru = known(False)
        rows = call('GET', 'my_stories?status=eq.queued&select=id,title,body&order=created_at')
        for r in rows or []:
            call('PATCH', f'my_stories?id=eq.{r["id"]}', {'status': 'processing'})
            open(f'{out}/{r["id"]}.txt', 'w', encoding='utf-8').write(r['body'])
            todo = [w for w in words(r['body']) if w not in ru]
            json.dump(todo, open(f'{out}/{r["id"]}.todo.json', 'w', encoding='utf-8'), ensure_ascii=False)
            print(r['id'], r['title'], f'слов всего {len(words(r["body"]))}, нужен перевод {len(todo)}')
        if not rows:
            print('очередь пуста')
    elif a[0] == 'push':
        sid, fill = a[1], json.load(open(a[2], encoding='utf-8'))
        body = call('GET', f'my_stories?id=eq.{sid}&select=body')[0]['body']
        ru, en = known(False), known(True)
        dru, den = {}, {}
        for w in words(body):
            if w in fill:
                f = fill[w]
                dru[w] = [f[0], f[1]]
                den[w] = [f[2], f[3]] if len(f) >= 4 else [f[0], f[1]]
            elif w in ru:
                dru[w] = ru[w]
                if w in en:
                    den[w] = en[w]
        missing = [w for w in words(body) if w not in dru]
        call('PATCH', f'my_stories?id=eq.{sid}', {
            'dict': dru, 'dict_en': den, 'status': 'ready', 'error': None,
            'finished_at': __import__('datetime').datetime.utcnow().isoformat() + 'Z'})
        print('готово', sid, f'слов в словаре {len(dru)}, без перевода {len(missing)}')
    elif a[0] == 'fail':
        call('PATCH', f'my_stories?id=eq.{a[1]}', {'status': 'failed', 'error': a[2]})
    else:
        sys.exit(__doc__)


main()
