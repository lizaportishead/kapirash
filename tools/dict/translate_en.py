#!/usr/bin/env python3
"""English version of a video's content: <id>.en.vtt, <id>.dict.en.json, <id>.quiz.en.json.

    ANTHROPIC_API_KEY=... translate_en.py app/assets/<id>      # reads <id>.ru.vtt, <id>.dict.json, <id>.quiz.json
    translate_en.py app/assets/<id> --dry-run                  # prints the first prompt of each kind
    TRANSLATE_FAKE=1 translate_en.py app/assets/<id>           # offline check of the plumbing ("[EN] " prefix)

Everything is derived from the finished Russian files, so run it after the Russian dictionary is final.
  * .en.vtt: the same cues and timings as .ru.vtt, translated text.
  * .dict.en.json: the same keys; [English gloss, English note]. Grammar vocabulary of the notes is converted
    mechanically (en_notes.py), only the remaining Russian (glosses, examples) goes to the model.
  * .quiz.en.json: the same structure and answers; titles, questions, options and explanations translated,
    the Serbian text («quotes», examples, Latin options) untouched.
The app falls back to the Russian files if an English one is missing.
"""
import argparse, json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from en_notes import note_to_en, cyrillic_runs  # noqa: E402

MODEL = os.environ.get('CLAUDE_MODEL', 'claude-haiku-5-5')
BATCH = 120
CYR = re.compile('[а-яёА-ЯЁ]')

PROMPT = """You translate Russian text into natural English for a learner app for Serbian ({what}).
Input: lines "id<TAB>text". Output: exactly the same ids, one line each, "id<TAB>English text", nothing else.
Rules: keep every Serbian/Latin word, number and punctuation mark as in the source; do not merge or split lines;
keep «…» quotations of Serbian text in straight quotes "…"; {extra}

{rows}"""
KINDS = {
    'cues': ('subtitle lines; each line is a fragment of a sentence', 'translate the fragment as it stands, even if it is cut mid-sentence.'),
    'glosses': ('short dictionary glosses of single words', 'give the shortest natural gloss (1-3 words); for verbs in a past form use the English past tense, etc.'),
    'runs': ('pieces of dictionary notes', 'these are short explanations such as "to begin; imperfective"; keep them short.'),
    'quiz': ('quiz questions, options and explanations', 'explanations look like «Serbian quote» followed by a Russian translation: keep the quote, translate the rest and write it as In the video: "Serbian quote" — English translation.'),
}


def translate(items, kind, dry=False):
    """items: list of unique Russian strings -> dict ru -> en."""
    items = [x for x in dict.fromkeys(items) if CYR.search(x)]
    out = {}
    what, extra = KINDS[kind]
    for i in range(0, len(items), BATCH):
        batch = items[i:i + BATCH]
        rows = '\n'.join(f'{j}\t{t}' for j, t in enumerate(batch))
        prompt = PROMPT.format(what=what, extra=extra, rows=rows)
        if dry:
            print(prompt)
            return out
        if os.environ.get('TRANSLATE_FAKE'):
            out.update({t: '[EN] ' + t for t in batch})
            continue
        import anthropic
        text = ''.join(b.text for b in anthropic.Anthropic().messages.create(
            model=MODEL, max_tokens=16000, messages=[{'role': 'user', 'content': prompt}]).content if b.type == 'text')
        got = {}
        for line in text.splitlines():
            m = re.match(r'(\d+)\t(.*)$', line)
            if m and int(m[1]) < len(batch):
                got[int(m[1])] = m[2].strip()
        for j, t in enumerate(batch):
            if j in got and got[j]:
                out[t] = got[j]
            else:
                print(f'no translation for {kind} {t[:40]!r}: left in Russian', file=sys.stderr)
        print(f'{kind}: {min(i + BATCH, len(items))}/{len(items)}', file=sys.stderr)
    return out


def do_vtt(base, dry):
    src = open(base + '.ru.vtt', encoding='utf-8').read()
    blocks = [b.strip().split('\n') for b in src.split('\n\n')]
    texts = [' ⏎ '.join(b[2:]) for b in blocks if len(b) >= 3 and '-->' in b[1]]
    tr = translate(texts, 'cues', dry)
    if dry:
        return
    out = []
    for b in blocks:
        if len(b) >= 3 and '-->' in b[1]:
            t = ' ⏎ '.join(b[2:])
            b = b[:2] + tr.get(t, t).split(' ⏎ ')
        out.append('\n'.join(b))
    open(base + '.en.vtt', 'w', encoding='utf-8').write('\n\n'.join(out))


def do_dict(base, dry):
    d = json.load(open(base + '.dict.json', encoding='utf-8'))
    notes = {k: note_to_en(v[1]) if v[1] else '' for k, v in d.items()}
    glosses = translate([v[0] for v in d.values()], 'glosses', dry)
    runs = translate([r for n in notes.values() for r in cyrillic_runs(n)], 'runs', dry)
    if dry:
        return
    out = {}
    for k, v in d.items():
        n = re.sub(r'[а-яёА-ЯЁ0-9][а-яёА-ЯЁ0-9 ,.\-/!?:…\'’]*[а-яёА-ЯЁ.]|[а-яёА-ЯЁ]', lambda m: runs.get(m[0], m[0]), notes[k])
        out[k] = [glosses.get(v[0], v[0]), n]
    with open(base + '.dict.en.json', 'w', encoding='utf-8') as fh:
        fh.write('{\n' + ',\n'.join(json.dumps(k, ensure_ascii=False) + ':' + json.dumps(v, ensure_ascii=False) for k, v in out.items()) + '\n}\n')


def do_quiz(base, dry):
    d = json.load(open(base + '.quiz.json', encoding='utf-8'))
    strings = []
    for s in d['sections']:
        strings += [s['title'], s['about']]
        for q in s['questions']:
            strings += [q['q'], *q['o'], q['e']]
    tr = translate(strings, 'quiz', dry)
    if dry:
        return
    T = lambda x: tr.get(x, x)
    for s in d['sections']:
        s['title'], s['about'] = T(s['title']), T(s['about'])
        for q in s['questions']:
            q['q'], q['o'], q['e'] = T(q['q']), [T(o) for o in q['o']], T(q['e'])
    json.dump(d, open(base + '.quiz.en.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('base', help='path without extension, e.g. app/assets/0Kc3ASUSPc0')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    for ext, fn in (('.ru.vtt', do_vtt), ('.dict.json', do_dict), ('.quiz.json', do_quiz)):
        if os.path.exists(a.base + ext):
            fn(a.base, a.dry_run)
        else:
            print(f'skip: {a.base}{ext} not found', file=sys.stderr)


if __name__ == '__main__':
    main()
