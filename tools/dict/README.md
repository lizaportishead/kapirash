# autodict: pre-fill the dictionary of a new video

```bash
python3 -m venv venv && venv/bin/pip install classla
venv/bin/python -c "import classla; classla.download('sr', dir='models')"   # ~160 MB, once
venv/bin/python tools/dict/autodict.py --assets app/assets --models models --out work/ app/assets/<id>.sr.vtt
```

- `work/auto.dict.json` — entries built from words/lemmas already in `app/assets/*.dict.json`
  (translation of the lemma + grammar note from the CLASSLA tags). The translation of an
  inflected form is the lemma's, so verbs show the infinitive: review if it matters.
- `work/todo.tsv` — `word, lemma, POS, grammar note` for words whose lemma is unknown anywhere:
  these still need a translation (by hand or batch-translated by a cheap model).

Hold-out check (video removed from the known set): 21–33 % of the missing words were filled
automatically, the rest are genuinely new vocabulary.

## translate_todo.py: translate what is left

```bash
venv/bin/pip install anthropic
ANTHROPIC_API_KEY=... venv/bin/python tools/dict/translate_todo.py work/todo.tsv --out work/translated.dict.json
```

Sends `todo.tsv` to `claude-haiku-5-5` (override with `CLAUDE_MODEL`) in batches of 60 and writes a
dict.json fragment. Uncertain words get a «?» at the end of the translation and are listed at the end.
The final `<id>.dict.json` = `auto.dict.json` + `translated.dict.json`. `--dry-run` prints the first prompt.

With `--en` the same call also returns English glosses and writes a second fragment next to the first
(`work/translated.dict.en.json`, notes in English: «lemma — gloss; gen. case pl.»). Merging works as above
(`auto.dict.json` has Russian notes: run it through `translate_en.py` below, or convert it with `en_notes.note_to_en`).

## translate_en.py: the English version of a finished video

Every video ships `<id>.en.vtt`, `<id>.dict.en.json` and `<id>.quiz.en.json` next to the Russian files
(for stories only `story_*.dict.en.json`); the app reads them when the interface is English and falls back to
the Russian ones when a file is missing. Once the Russian `<id>.ru.vtt`, `<id>.dict.json` and `<id>.quiz.json` are final:

```bash
ANTHROPIC_API_KEY=... venv/bin/python tools/dict/translate_en.py app/assets/<id>
```

- `.en.vtt` — the same cues and timings as `.ru.vtt`, text translated;
- `.dict.en.json` — the same keys, `[English gloss, English note]`. The grammar vocabulary of the notes is converted
  mechanically by `en_notes.py` (nom/gen/dat/acc/instr/loc/voc, sg./pl., 1st/2nd/3rd pers., past, future, imperative,
  conditional, comparative, superlative, masc./fem./neut. — exactly the abbreviations `Word.describeForm` /
  `_enNoteToRu` in `app/lib/store.dart` parse); only the remaining Russian (glosses, examples) goes to the model;
- `.quiz.en.json` — the same structure and answers, titles/questions/options/explanations translated, the Serbian
  text untouched.

Rules to keep when editing the English files by hand: the note starts with the lemma («lemma — gloss; gen. case pl.»)
or, for a form without a lemma, with a part of speech («noun», «verb», «adj», «adv», «infinitive»…); do not put
grammar words («past», «future», «plural», «comparative»…) into the gloss part, the parser would read them as
the grammar of the form. `--dry-run` prints the first prompt of each kind; `TRANSLATE_FAKE=1` checks the plumbing offline.
