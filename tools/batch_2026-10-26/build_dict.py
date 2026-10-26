import sys, os, re, json, glob
sys.path.insert(0, os.path.dirname(__file__))
import importlib; CUES = importlib.import_module(os.environ.get('CUES','cues')).CUES
a, b = {}, {}
for f in sorted(glob.glob('app/assets/*.dict.json')):
    if not f.endswith('.en.json'): a.update(json.load(open(f)))
for f in sorted(glob.glob('app/assets/*.dict.en.json')): b.update(json.load(open(f)))
new_ru, new_en = {}, {}
for l in open(os.path.join(os.path.dirname(__file__), os.environ.get('DICT','dict.tsv'))):
    if not l.strip(): continue
    w, r, rn, e, en = l.rstrip('\n').split('\t')
    new_ru[w] = [r, rn]; new_en[w] = [e, en]
extra_en = {
 'andrija': ['Andrija', 'name'],
 'brineš': ['you worry, take care', 'brinuti — to worry, care; 2nd pers. sg.'],
 'ljutiš': ['you are angry', 'ljutiti se — to be angry; 2nd pers. sg.'],
 'onoliko': ['that much', 'onoliko — that much, so much'],
 'parovima': ['pairs', 'par — pair; dat. case pl.'],
 'hleb': ['bread', 'hleb — bread (masc.)'],
 'mrtva': ['dead', 'mrtav — dead; fem.'],
 'muškarca': ['man', 'muškarac — man; acc. case'],
 'specijalni': ['special', 'specijalan — special; masc.'],
 'zamisli': ['imagine', 'zamisliti — to imagine; imperative 2nd pers. sg.'],
 'slušaš': ['you listen', 'slušati — to listen; 2nd pers. sg.'],
}
cw = lambda w: re.sub(r"[^\w'-]", '', w).replace('_', '')
def dump(d, path):
    open(path, 'w').write('{\n' + ',\n'.join(f'{json.dumps(k, ensure_ascii=False)}:{json.dumps(v, ensure_ascii=False)}' for k, v in sorted(d.items())) + '\n}\n')
OUT = sys.argv[1]
for vid, cues in CUES.items():
    ws = sorted({cw(w).lower() for c in cues for w in c[2].split() if cw(w)})
    ru, en = {}, {}
    for w in ws:
        ru[w] = new_ru.get(w) or a[w]
        en[w] = new_en.get(w) or b.get(w) or extra_en[w]
    dump(ru, f'{OUT}/{vid}.dict.json'); dump(en, f'{OUT}/{vid}.dict.en.json')
    print(vid, len(ru))
