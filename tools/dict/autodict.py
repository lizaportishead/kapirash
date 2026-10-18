#!/usr/bin/env python3
"""Auto-fill the dictionary of a new video from the words we already know.

    autodict.py --assets app/assets --out work/ <id>.sr.vtt [...]

Every word of the Serbian text needs an entry in <id>.dict.json (key = lowercased
cleanWord, value = [translation, note]). This script:

1. reuses the entry of any video already in --assets (first one wins);
2. for the rest, lemmatises with CLASSLA; if the lemma is known, builds the entry from
   the lemma's translation plus a grammar note in the app's style ("lemma — перевод; род. падеж");
3. writes what is still unknown (lemma not in any dictionary) to todo.tsv, one line per word
   (word, lemma, POS, grammar note) -- only those need a translation, by hand or by a model.

Outputs in --out: auto.dict.json (steps 1-2) and todo.tsv (step 3).
Requires: pip install classla; classla.download('sr', dir=<--models>).
"""
import argparse, glob, json, os, re, sys

CASE = {'Nom': 'им.', 'Gen': 'род.', 'Dat': 'дат.', 'Acc': 'вин.', 'Voc': 'зват.', 'Loc': 'предл.', 'Ins': 'твор.'}
GENDER = {'Masc': 'м. р.', 'Fem': 'ж. р.', 'Neut': 'ср. р.'}
NUM = {'Sing': 'ед. ч.', 'Plur': 'мн. ч.'}
POS_LABEL = {'ADV': 'наречие', 'ADP': 'предлог', 'CCONJ': 'союз', 'SCONJ': 'союз', 'PART': 'частица',
             'INTJ': 'междометие', 'PRON': 'местоимение', 'NUM': 'числительное'}


def clean_word(w):
    return re.sub(r"[^\w'-]", '', w, flags=re.UNICODE).replace('_', '')


def feats_dict(feats):
    return dict(p.split('=', 1) for p in feats.split('|')) if feats and feats != 'None' else {}


def grammar(upos, f):
    """Short Russian grammar note from UD features."""
    num, gen = NUM.get(f.get('Number', ''), ''), GENDER.get(f.get('Gender', ''), '')
    if upos in POS_LABEL:
        return POS_LABEL[upos] + ((' + ' + CASE[f['Case']] + ' падеж') if upos == 'ADP' and f.get('Case') in CASE else '')
    if upos in ('VERB', 'AUX'):
        if f.get('VerbForm') == 'Inf':
            return 'инфинитив'
        if f.get('Mood') == 'Imp':
            return 'повел. накл.'
        if f.get('VerbForm') == 'Part':
            return ' '.join(x for x in ('прош. вр.', gen, num) if x)
        if f.get('VerbForm') == 'Conv':
            return 'деепричастие'
        if f.get('Person'):
            tense = {'Fut': 'буд. вр., ', 'Past': 'прош. вр., '}.get(f.get('Tense', ''), '')
            return tense + f'{f["Person"]} л. {num}'.strip()
        return ''
    parts = []
    if f.get('Degree') == 'Sup':
        parts.append('превосх. степень')
    elif f.get('Degree') == 'Cmp':
        parts.append('сравнит. степень')
    if f.get('Case') in CASE:
        parts.append(CASE[f['Case']] + (' мн. ч.' if f.get('Number') == 'Plur' else ' падеж'))
    elif num:
        parts.append(num)
    if gen and upos in ('ADJ', 'DET', 'NOUN') and not f.get('Case'):
        parts.append(gen)
    return '; '.join(parts)


def read_cues(path):
    cues, buf = [], []
    for line in open(path, encoding='utf-8').read().splitlines() + ['']:
        if '-->' in line or re.fullmatch(r'\d+', line) or line.startswith('WEBVTT'):
            continue
        if line.strip():
            buf.append(line.strip())
        elif buf:
            cues.append(' '.join(buf))
            buf = []
    return cues


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('vtt', nargs='+')
    ap.add_argument('--assets', default='app/assets')
    ap.add_argument('--out', default='.')
    ap.add_argument('--models', default='models')
    a = ap.parse_args()

    known = {}
    for f in sorted(glob.glob(os.path.join(a.assets, '*.dict.json'))):
        for k, v in json.load(open(f, encoding='utf-8')).items():
            known.setdefault(k, v)

    # lemma -> translation, also read from notes of the form "lemma — перевод; ..." (most lemmas are not
    # keys of their own, only their forms occur in videos)
    lemmas = {}
    for k, v in known.items():
        lemmas.setdefault(k, v[0])
        m = re.match(r"([^\W\d_][\w-]*)(?: se)? — ([^;(]+)", v[1] or '')
        if m:
            lemmas.setdefault(m[1].lower(), m[2].strip())

    # needed words: key -> example cue (for tagging in context)
    need = {}
    for path in a.vtt:
        for cue in read_cues(path):
            for raw in cue.split():
                k = clean_word(raw).lower()
                if k and k not in known:
                    need.setdefault(k, cue)
    print(f'{len(need)} words missing from {len(known)} known', file=sys.stderr)

    auto, todo = {}, []
    if need:
        import classla
        nlp = classla.Pipeline('sr', dir=a.models, processors='tokenize,pos,lemma', use_gpu=False, logging_level='ERROR')
        by_cue, seen = {}, set()
        for k, cue in need.items():
            by_cue.setdefault(cue, set()).add(k)
        for cue, keys in by_cue.items():
            for s in nlp(cue).sentences:
                for w in s.words:
                    k = clean_word(w.text).lower()
                    if k not in keys or k in auto or k in seen:
                        continue
                    lemma = (w.lemma or k).lower()
                    note = grammar(w.upos, feats_dict(w.feats))
                    lem = lemmas.get(lemma)
                    if lem and w.upos not in ('PUNCT', 'SYM', 'X'):
                        tr = lem.split(',')[0].strip() if k != lemma else lem
                        head = lemma if k == lemma else f'{lemma} — {lem}'
                        auto[k] = [tr, '; '.join(x for x in ((head if k != lemma else ''), note) if x)]
                    else:
                        todo.append((k, lemma, w.upos, note))
                        seen.add(k)
        # words the tagger split or dropped
        for k in need:
            if k not in auto and not any(t[0] == k for t in todo):
                todo.append((k, '', '?', ''))

    os.makedirs(a.out, exist_ok=True)
    json.dump(auto, open(os.path.join(a.out, 'auto.dict.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    with open(os.path.join(a.out, 'todo.tsv'), 'w', encoding='utf-8') as fh:
        for row in sorted(todo):
            fh.write('\t'.join(row) + '\n')
    print(f'auto-filled {len(auto)}, need translation {len(todo)}', file=sys.stderr)


if __name__ == '__main__':
    main()
