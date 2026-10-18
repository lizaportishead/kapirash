#!/usr/bin/env python3
"""Translate the words left in todo.tsv (output of autodict.py) with a small model, in batches.

    ANTHROPIC_API_KEY=... translate_todo.py work/todo.tsv --out work/translated.dict.json

Each line of todo.tsv: word, lemma, POS, grammar note. The result is a dict.json fragment in the
app's format: key -> [translation of the form, "lemma — перевод лемм; grammar note"].
Merge it with auto.dict.json (autodict.py) to get the whole <id>.dict.json.
Words the model is unsure about come back with "?" in the translation: check those by hand.
"""
import argparse, json, os, re, sys

MODEL = os.environ.get('CLAUDE_MODEL', 'claude-haiku-5-5')
BATCH = 60

PROMPT = """Ты помогаешь составлять словарь сербского (екавица) для русскоязычного ученика.
Для каждого слова ниже дана форма, лемма по тегеру, часть речи и грамматическая пометка.
Верни JSON-массив строго такой же длины и в том же порядке, каждый элемент:
{{"w": форма, "tr": перевод ИМЕННО ЭТОЙ ФОРМЫ на русский (глагол в нужном времени/лице, существительное в нужном числе; кратко, 1-3 слова), "lemma": лемма (исправь, если тегер ошибся, иначе как дана), "ltr": перевод леммы (инфинитив / им. п. ед. ч.)}}
Если слово не сербское (англицизм, имя собственное), в "tr" дай перевод или транслитерацию, в "ltr" пометку вроде «англ. black — чёрный».
Если не уверен, добавь «?» в конец "tr". Никакого текста кроме JSON.

Слова:
{rows}"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('todo')
    ap.add_argument('--out', default='translated.dict.json')
    ap.add_argument('--dry-run', action='store_true', help='print the first prompt and exit')
    a = ap.parse_args()

    rows = [l.rstrip('\n').split('\t') for l in open(a.todo, encoding='utf-8') if l.strip()]
    rows = [(r + ['', '', '', ''])[:4] for r in rows]
    batches = [rows[i:i + BATCH] for i in range(0, len(rows), BATCH)]
    if a.dry_run:
        print(PROMPT.format(rows='\n'.join('\t'.join(r) for r in batches[0])) if batches else 'nothing to translate')
        return

    import anthropic
    client = anthropic.Anthropic()
    out = {}
    for n, batch in enumerate(batches, 1):
        msg = client.messages.create(
            model=MODEL, max_tokens=8000,
            messages=[{'role': 'user', 'content': PROMPT.format(rows='\n'.join('\t'.join(r) for r in batch))}])
        text = ''.join(b.text for b in msg.content if b.type == 'text')
        m = re.search(r'\[.*\]', text, re.S)
        try:
            items = json.loads(m.group(0))
        except Exception:
            print(f'batch {n}: unreadable answer, skipped', file=sys.stderr)
            continue
        by_word = {i.get('w', '').lower(): i for i in items if isinstance(i, dict)}
        for word, lemma, _pos, gram in batch:
            i = by_word.get(word)
            if not i or not i.get('tr'):
                print(f'no translation for {word}', file=sys.stderr)
                continue
            lem = i.get('lemma') or lemma
            ltr = i.get('ltr') or ''
            note = '; '.join(x for x in ((f'{lem} — {ltr}' if lem != word and ltr else ltr if ltr.startswith('англ.') else ''), gram) if x)
            out[word] = [i['tr'].strip(), note]
        print(f'batch {n}/{len(batches)} done', file=sys.stderr)

    json.dump(out, open(a.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    unsure = [w for w, v in out.items() if v[0].endswith('?')]
    print(f'{len(out)}/{len(rows)} translated, {len(unsure)} marked uncertain: {", ".join(unsure[:30])}', file=sys.stderr)


if __name__ == '__main__':
    main()
