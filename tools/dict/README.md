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
