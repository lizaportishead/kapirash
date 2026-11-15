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
 '1936': ['1936 (year)', 'number'],
 'ambicije': ['ambitions', 'ambicija — ambition; nom. pl./gen. sg.'],
 'balans': ['balance', 'balans — balance; nom./acc.'],
 'berlina': ['Berlin', 'Berlin — Berlin; gen.'],
 'ekonomska': ['economic', 'ekonomski — economic; nom. fem.'],
 'ekonomskih': ['economic', 'ekonomski — economic; gen. pl.'],
 'glasova': ['votes', 'glas — vote, voice; gen. pl.'],
 'grupama': ['groups', 'grupa — group; instr./dat. pl.'],
 'ideologija': ['ideologies', 'ideologija — ideology; gen. pl.'],
 'interesima': ['interests', 'interes — interest; instr./dat. pl.'],
 'iskoristio': ['used', 'iskoristiti — to use; past masc.'],
 'italije': ['Italy', 'Italija — Italy; gen.'],
 'izgovorio': ['pronounced', 'izgovoriti — to pronounce; past masc.'],
 'lika': ['guy, figure', 'lik — figure, guy; gen.'],
 'maloj': ['small', 'mali — small; loc. fem.'],
 'nacije': ['nations', 'nacija — nation; nom. pl./gen. sg.'],
 'nezadovoljstvo': ['dissatisfaction', 'nezadovoljstvo — dissatisfaction; nom.'],
 'obezbedi': ['secure', 'obezbediti — to secure; present 3rd sg.'],
 'ostatka': ['rest, remainder', 'ostatak — remainder; gen.'],
 'partnera': ['partner', 'partner — partner; gen./acc.'],
 'podržali': ['supported', 'podržati — to support; past masc. pl.'],
 'političkih': ['political', 'politički — political; gen. pl.'],
 'popularizaciju': ['popularization', 'popularizacija — popularization; acc.'],
 'pozovu': ['invite', 'pozvati — to invite; present 3rd pl.'],
 'premijer': ['prime minister', 'premijer — prime minister; nom.'],
 'prestiž': ['prestige', 'prestiž — prestige; nom./acc.'],
 'privremeno': ['temporarily', 'privremeno — temporarily'],
 'propagandu': ['propaganda', 'propaganda — propaganda; acc.'],
 'proširio': ['expanded', 'proširiti se — to expand; past masc.'],
 'ranih': ['early', 'rani — early; gen./loc. pl.'],
 'ratni': ['war (adj.)', 'ratni — war; masc.'],
 'sazvali': ['convened', 'sazvati — to convene; past masc. pl.'],
 'stvore': ['create', 'stvoriti — to create; present 3rd pl.'],
 'svetski': ['world (adj.)', 'svetski — world; masc.'],
 'uspona': ['rise', 'uspon — rise; gen.'],
 'učestvovati': ['to take part', 'učestvovati — to take part; infinitive'],
 'vojno': ['militarily', 'vojno — militarily'],
 'zločine': ['crimes', 'zločin — crime; acc. pl.'],
 '1954': ['1954 (year)', 'number'],
 'australija': ['Australia', 'Australija — Australia; nom.'],
 'australije': ['Australia', 'Australija — Australia; gen.'],
 'australijski': ['Australian', 'australijski — Australian; masc.'],
 'blisko': ['close, closely', 'blisko — close'],
 'borbi': ['struggle', 'borba — struggle; loc./dat.'],
 'bosne': ['Bosnia', 'Bosna — Bosnia; gen.'],
 'emancipacija': ['emancipation', 'emancipacija — emancipation; nom.'],
 'francuska': ['France', 'Francuska — France; nom.'],
 'francuskoj': ['French', 'francuski — French; loc. fem.'],
 'grb': ['coat of arms', 'grb — coat of arms; nom./acc.'],
 'grba': ['coat of arms', 'grb — coat of arms; gen.'],
 'identitet': ['identity', 'identitet — identity; nom./acc.'],
 'jasna': ['clear', 'jasan — clear; fem.'],
 'kosova': ['Kosovo', 'Kosovo — Kosovo; gen.'],
 'međunarodno': ['internationally', 'međunarodno — internationally'],
 'nastalo': ['arose', 'nastati — to arise; past neut.'],
 'negativan': ['negative', 'negativan — negative; masc.'],
 'neretko': ['often', 'neretko — often'],
 'nezavisnost': ['independence', 'nezavisnost — independence; acc.'],
 'nezgodan': ['awkward', 'nezgodan — awkward; masc.'],
 'nikom': ['nobody', 'niko — nobody; dat./instr./loc.'],
 'nužno': ['necessarily', 'nužno — necessarily'],
 'partije': ['party', 'partija — party; gen.'],
 'pobedu': ['victory', 'pobeda — victory; acc.'],
 'politički': ['political', 'politički — political; masc.'],
 'pomenuli': ['mentioned', 'pomenuti — to mention; past masc. pl.'],
 'potvrdila': ['confirmed', 'potvrditi — to confirm; past fem.'],
 'prag': ['Prague', 'Prag — Prague; nom.'],
 'predstavljao': ['represented', 'predstavljati — to represent; past masc.'],
 'predstavnici': ['representatives', 'predstavnik — representative; nom. pl.'],
 'prepreka': ['obstacles', 'prepreka — obstacle; gen. pl.'],
 'primeri': ['examples', 'primer — example; nom. pl.'],
 'protesta': ['protest', 'protest — protest; gen.'],
 'referendum': ['referendum', 'referendum — referendum; nom./acc.'],
 'rusije': ['Russia', 'Rusija — Russia; gen.'],
 'ruske': ['Russian', 'ruski — Russian; gen. fem.'],
 'sigurnošću': ['certainty', 'sigurnost — certainty; instr.'],
 'simbolizuje': ['symbolizes', 'simbolizovati — to symbolize; present 3rd sg.'],
 'slovačke': ['Slovakia', 'Slovačka — Slovakia; gen.'],
 'slovenije': ['Slovenia', 'Slovenija — Slovenia; gen.'],
 'solidarnosti': ['solidarity', 'solidarnost — solidarity; gen.'],
 'spoje': ['join, merge', 'spojiti — to join; present 3rd pl.'],
 'teritorija': ['territories', 'teritorija — territory; gen. pl.'],
 'ujedinjenih': ['united', 'ujedinjen — united; gen. pl.'],
 'uniji': ['union', 'unija — union; loc.'],
 'ustav': ['constitution', 'ustav — constitution; nom./acc.'],
 'velikodušnost': ['generosity', 'velikodušnost — generosity; nom.'],
 'zajedničko': ['common, shared', 'zajednički — common; neut.'],
 'zajedničku': ['common, shared', 'zajednički — common; acc. fem.'],
 'zastavama': ['flags', 'zastava — flag; instr./dat. pl.'],
 'zastave': ['flags', 'zastava — flag; gen. sg./nom. pl.'],
 'zauzeli': ['seized', 'zauzeti — to seize; past masc. pl.'],
 'španije': ['Spain', 'Španija — Spain; gen.'],
 'španiji': ['Spain', 'Španija — Spain; loc.'],
 'životni': ['life (adj.)', 'životni — life; masc.'],
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
        en[w] = new_en.get(w) or b.get(w) or extra_en.get(w) or MISSING.append(w)
    print('NO EN', sorted(set(MISSING))); en = {k: v for k, v in en.items() if v}
    dump(ru, f'{OUT}/{vid}.dict.json'); dump(en, f'{OUT}/{vid}.dict.en.json')
    print(vid, len(ru))
