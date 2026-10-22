"""Russian grammar notes of the dictionaries -> English notes ("lemma — gloss; gen. case pl.").

The app (Word.describeForm / _enNoteToRu in app/lib/store.dart) reads the English abbreviations
nom/gen/dat/acc/instr/loc/voc (+ "case"), sg./pl., 1st/2nd/3rd pers., past, future, imperative,
conditional, comparative, superlative, masc./fem./neut.; keep to exactly these.
`note_to_en` converts the grammar vocabulary mechanically; what stays Cyrillic afterwards
(glosses, quoted examples) is returned by `cyrillic_runs` for translation.
"""
import re

CASE = [
    (r'именительн\w*|им\.', 'nom.'),
    (r'родительн\w*|род\.(?:\s*п\.)?', 'gen.'),
    (r'дательн\w*|дат\.', 'dat.'),
    (r'винительн\w*|вин\.', 'acc.'),
    (r'творительн\w*|творит\.|твор\.|тв\.', 'instr.'),
    (r'предложн\w*|предл\.|местн\w*\.?|мест\.', 'loc.'),
    (r'звательн\w*|зват\.', 'voc.'),
]
_P = {'1': '1st', '2': '2nd', '3': '3rd'}
REPL = [
    (r'(\d)\s*л\.\s*ед\.\s*ч\.?', lambda m: _P[m[1]] + ' pers. sg.'),
    (r'(\d)\s*л\.\s*мн\.\s*ч\.?', lambda m: _P[m[1]] + ' pers. pl.'),
    (r'(\d)\s*л\.', lambda m: _P[m[1]] + ' pers.'),
    (r'множественное число|мн\.\s*числа?|мн\.\s*ч\.?|мн\.\s*число', 'pl.'),
    (r'единственное число|ед\.\s*числа?|ед\.\s*ч\.?|ед\.\s*число', 'sg.'),
    (r'прош\.\s*вр\.?|прошедшего времени|прошедшее время', 'past'),
    (r'буд\.\s*вр\.?|будущего времени|будущее время', 'future'),
    (r'повел\.\s*накл\.?|повелит\.|повелительное наклонение', 'imperative'),
    (r'сослагат\.?\w*(?:\s+наклонени\w*)?|условн\w*(?:\s+наклонени\w*)?', 'conditional'),
    (r'сравнительн\w*\s+степен\w*|сравн\.\s*степень|сравн\.', 'comparative'),
    (r'превосходн\w*\s+степен\w*|превосх\.\s*степень|превосх\.', 'superlative'),
    (r'(?<![а-яё])м\.\s*р\.', 'masc.'),
    (r'(?<![а-яё])ж\.\s*р\.', 'fem.'),
    (r'(?<![а-яё])ср\.\s*р\.', 'neut.'),
    (r'падежа?', 'case'),
    (r'сущ\.', 'noun'), (r'существительное', 'noun'),
    (r'наречие', 'adverb'), (r'предлог', 'preposition'), (r'местоимение', 'pronoun'),
    (r'союз', 'conjunction'), (r'частица', 'particle'), (r'числительное', 'numeral'),
    (r'глагол', 'verb'), (r'прилагательное|прилаг\.|прил\.', 'adj'),
    (r'инфинитив', 'infinitive'), (r'причастие|прич\.', 'participle'),
    (r'междометие', 'interjection'),
    (r'несов\.\s*вид', 'imperfective'), (r'сов\.\s*вид', 'perfective'),
    (r'англ\.', 'English'), (r'разг\.', 'colloquial'),
]
RUN = re.compile(r'[а-яёА-ЯЁ0-9][а-яёА-ЯЁ0-9 ,.\-/!?:…\'’]*[а-яёА-ЯЁ.]|[а-яёА-ЯЁ]')


def note_to_en(s):
    for p, r in REPL[:3]:
        s = re.sub(p, r, s)
    for p, r in CASE:
        s = re.sub(p, r, s)
    for p, r in REPL[3:]:
        s = re.sub(p, r, s)
    s = re.sub(r'(?<=\.)\s*п\.', ' case', s)
    s = re.sub(r'(?<=[a-z\.])\s+от(?=[\s)]|$)', ' of', s)
    return s.replace('краткая форма', 'short form').replace('полная форма', 'full form').replace('форма', 'form')


def cyrillic_runs(s):
    return RUN.findall(s)
