import sys, os, re, json, glob
sys.path.insert(0, os.path.dirname(__file__))
import importlib; CUES = importlib.import_module(os.environ.get('CUES','cues')).CUES
a, b = {}, {}
for f in sorted(glob.glob('app/assets/*.dict.json')):
    if not f.endswith('.en.json'): a.update(json.load(open(f)))
for f in sorted(glob.glob('app/assets/*.dict.en.json')): b.update(json.load(open(f)))
new_ru, new_en = {}, {}; MISSING = []
for l in open(os.path.join(os.path.dirname(__file__), os.environ.get('DICT','dict.tsv'))):
    if not l.strip(): continue
    w, r, rn, e, en = l.rstrip('\n').split('\t')
    new_ru[w] = [r, rn]; new_en[w] = [e, en]
extra_en = {
 'fraze': ['phrases', 'fraza — phrase; acc. pl.'],
 'hrabrost': ['courage', 'hrabrost — courage; acc. case'],
 'matematika': ['mathematics', 'matematika — math'],
 'matematiku': ['mathematics', 'matematika — math; acc. case'],
 'metode': ['methods', 'metoda — method; acc. pl.'],
 'novoj': ['new', 'nov — new; fem. loc./dat. case'],
 'periodima': ['periods', 'period — period; loc. pl.'],
 'podcast': ['podcast', 'podcast — podcast'],
 'pojedina': ['some, certain', 'pojedin — individual, certain; neut. pl.'],
 'programa': ['program', 'program — program; gen. case'],
 'pronađite': ['find', 'pronaći — to find; imperative 2nd pers. pl.'],
 'treninge': ['workouts', 'trening — workout; acc. pl.'],
 'upornost': ['persistence', 'upornost — persistence; acc. case'],
 'zabavno': ['fun', 'zabavan — fun; neut.'],
 'zajednicu': ['community', 'zajednica — community; acc. case'],
 'zemalja': ['countries', 'zemlja — country; gen. pl.'],
 'čitali': ['read', 'čitati — to read; past masc. pl.'],
 'španski': ['Spanish', 'španski — Spanish'],
 'španskog': ['Spanish', 'španski — Spanish; gen. case'],
 'bezbedan': ['safe', 'bezbedan — safe; masc.'],
 'dvojicu': ['two (of them)', 'dvojica — two men; acc. case'],
 'kraljevu': ["king's", 'kraljev — king\'s; fem. acc. case'],
 'morsku': ['sea (adj.)', 'morski — sea, marine; fem. acc. case'],
 'sresti': ['to meet', 'sresti — to meet; infinitive'],
}
extra_en.update({
 'devojaka': ['girls', 'devojka — girl; gen. pl.'],
 'devojkama': ['girls', 'devojka — girl; dat. pl.'],
 'interesu': ['interest', 'interes — interest; loc.'],
 'iskustava': ['experiences', 'iskustvo — experience; gen. pl.'],
 'koleginica': ['colleagues (f.)', 'koleginica — colleague (f.); gen. pl.'],
 'medicini': ['medicine, medical school', 'medicina — medicine; loc.'],
 'mihajlović': ['Mihajlović', 'surname'],
 'nailazila': ['came across', 'nailaziti — to come across; past fem.'],
 'obavezama': ['obligations', 'obaveza — obligation; instr. pl.'],
 'oslobođeni': ['exempt', 'osloboditi — to free, exempt; passive masc. pl.'],
 'podkast': ['podcast', 'podkast — podcast; nom.'],
 'podkasta': ['podcast', 'podkast — podcast; gen.'],
 'podnese': ['is submitted', 'podneti — to submit; present 3rd sg.'],
 'podnesu': ['submit', 'podneti — to submit; present 3rd pl.'],
 'pokazale': ['showed', 'pokazati — to show; past fem. pl.'],
 'prevodu': ['translation', 'prevod — translation; loc.'],
 'redakcije': ['newsroom', 'redakcija — editorial office; gen.'],
 'seminar': ['seminar', 'seminar — seminar; acc.'],
 'student': ['student', 'student — student; nom.'],
 'studentkinja': ['female student', 'studentkinja — female student; nom.'],
 'studentska': ['student (adj.)', 'studentski — student; neut. pl./fem.'],
 'studija': ['studies', 'studije — studies; gen. pl.'],
 'svesna': ['aware', 'svestan — aware; fem.'],
 'tomka': ['Tomka', 'surname'],
 'univerziteta': ['university', 'univerzitet — university; gen.'],
 'urednik': ['editor', 'urednik — editor; nom.'],
 'urednika': ['editor', 'urednik — editor; gen.'],
 'važi': ['applies', 'važiti — to apply, be valid; present 3rd sg.'],
 'vladimir': ['Vladimir', 'name'],
 'zadužen': ['in charge', 'zadužen — responsible; masc.'],
 'šef': ['head, chief', 'šef — head, boss; nom.'],
})
cw = lambda w: re.sub(r"[^\w'-]", '', w).replace('_', '')
def dump(d, path):
    open(path, 'w').write('{\n' + ',\n'.join(f'{json.dumps(k, ensure_ascii=False)}:{json.dumps(v, ensure_ascii=False)}' for k, v in sorted(d.items())) + '\n}\n')
OUT = sys.argv[1]
for vid, cues in CUES.items():
    ws = sorted({cw(w).lower() for c in cues for w in c[2].split() if cw(w)})
    ru, en = {}, {}
    for w in ws:
        ru[w] = new_ru.get(w) or a[w]
        en[w] = new_en.get(w) or b.get(w) or extra_en.get(w) or MISSING.append(w)
    print('NO EN', sorted(set(MISSING))); en = {k: v for k, v in en.items() if v}
    dump(ru, f'{OUT}/{vid}.dict.json'); dump(en, f'{OUT}/{vid}.dict.en.json')
    print(vid, len(ru))
