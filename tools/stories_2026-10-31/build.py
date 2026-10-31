import sys, os, re, json, glob
sys.path.insert(0, '../dict'); import en_notes
HERE=os.getcwd(); ROOT=os.path.abspath('../..'); A=ROOT+'/app/assets'
exec(open('quizzes.py').read())
cw = lambda w: re.sub(r"[^\w'-]", '', w).replace('_', '')
a, b = {}, {}
for f in sorted(glob.glob(A+'/*.dict.json')):
    if not f.endswith('.en.json') and 'story_' not in f.split('/')[-1] or True:
        if not f.endswith('.en.json'): a.update(json.load(open(f)))
for f in sorted(glob.glob(A+'/*.dict.en.json')): b.update(json.load(open(f)))
nru, nen = {}, {}
for l in open('dict.psv'):
    w, lem, ru, en, gram, rl, el = l.rstrip('\n').split('|')
    g = re.sub(r'\s*\((имя|фамилия|название)\)', '', gram)
    nru[w] = [ru, f'{lem} — {rl}; {g}']
    ge = en_notes.note_to_en(g)
    assert not re.search('[а-яё]', ge), (w, ge)
    nen[w] = [en, f'{lem} — {el}; {ge}']

EXTRA_EN = {
 'divan': ['wonderful', 'divan — wonderful; masc.'],
 'dozvolu': ['permit', 'dozvola — permit; acc. case'],
 'dvesta': ['two hundred', 'dvesta — two hundred; numeral'],
 'garantuje': ['guarantees', 'garantovati — to guarantee; 3rd pers. sg.'],
 'izabranog': ['chosen, personal (doctor)', 'izabran — chosen; acc. case masc.'],
 'kriješ': ['you hide', 'kriti se — to hide; 2nd pers. sg.'],
 'očekuje': ['expects', 'očekivati — to expect; 3rd pers. sg.'],
 'pedeset': ['fifty', 'pedeset — fifty'],
 'petrović': ['Petrović', 'surname'],
 'pečat': ['stamp', 'pečat — stamp; masc.'],
 'pisalo': ['was written', 'pisati — to write; past neut. sg.'],
 'plaši': ['is afraid', 'plašiti se — to be afraid; 3rd pers. sg.'],
 'pojela': ['ate', 'pojesti — to eat up; past fem. sg.'],
 'probao': ['tried', 'probati — to try; past masc. sg.'],
 'rešili': ['solved', 'rešiti — to solve; past masc. pl.'],
 'sačekajte': ['wait', 'sačekati — to wait; imperative 2nd pers. pl.'],
 'skuvala': ['cooked', 'skuvati — to cook; past fem. sg.'],
 'solidarni': ['joint', 'solidaran — joint; masc. nom. case'],
 'stana': ['apartment', 'stan — apartment; gen. case'],
 'tekao': ['flowed', 'teći — to flow; past masc. sg.'],
 'uključeni': ['included, switched on', 'uključen — included; masc. pl.'],
 'zdravlja': ['health', 'zdravlje — health; gen. case'],
 'zvono': ['bell, ring', 'zvono — bell, ring; neut.'],
 'čuva': ['protects', 'čuvati — to protect; 3rd pers. sg.'],
 'šezdeset': ['sixty', 'šezdeset — sixty; numeral'],
}
OVR_RU = {'pisalo': ['было написано', 'pisati — писать; прош. вр. ср. р. ед. ч.'],
          'uključeni': ['включены', 'uključen — включённый; им. падеж м. р. мн. ч.'],
          'solidarni': ['солидарный', 'solidaran — солидарный; им. падеж м. р. ед. ч.']}
def dump(d, path):
    open(path, 'w').write('{\n' + ',\n'.join(f'{json.dumps(k, ensure_ascii=False)}:{json.dumps(v, ensure_ascii=False)}' for k, v in sorted(d.items())) + '\n}\n')
noen = set()
for sid, d in Q.items():
    txt = open(f'{sid}.txt').read(); low = txt.lower()
    ws = sorted({cw(w).lower() for w in txt.split() if cw(w)})
    ru, en = {}, {}
    for w in ws:
        ru[w] = OVR_RU.get(w) or nru.get(w) or a[w]
        e = nen.get(w) or EXTRA_EN.get(w) or b.get(w)
        if not e: noen.add(w)
        else: en[w] = e
    dump(ru, f'{A}/{sid}.dict.json'); dump(en, f'{A}/{sid}.dict.en.json')
    secs = [('M','Смысл','Meaning','idea','Что происходит в рассказе','What happens in the story'),
            ('L','Лексика','Vocabulary','translate','Слова из рассказа и их перевод','Words from the story and their translations'),
            ('G','Грамматика','Grammar','puzzle','Падежи и формы глаголов','Cases and verb forms')]
    qru={'sections':[]}; qen={'sections':[]}
    for k, tr, te, icon, ar, ae in secs:
        r_, e_ = [], []
        for x in d[k]:
            if k=='M':
                qr, qe, orr, oe, an, quote, een = x
                assert quote.lower() in low, (sid, quote)
                r_.append({"q":qr,"o":orr,"a":an,"e":quote}); e_.append({"q":qe,"o":oe,"a":an,"e":een})
            elif k=='L':
                q, orr, oe, an, err, een = x
                assert q.replace('*','').lower().rstrip('.?!,') in low, (sid, q)
                t="Выбери перевод выделенного слова"
                r_.append({"t":t,"q":q,"o":orr,"a":an,"e":err}); e_.append({"t":t,"q":q,"o":oe,"a":an,"e":een})
            else:
                q, o, an, err, een = x
                assert q.replace('___', o[an]).lower().rstrip('.?!,') in low, (sid, q, o[an])
                r_.append({"t":GT,"q":q,"o":o,"a":an,"e":err}); e_.append({"t":GT,"q":q,"o":o,"a":an,"e":een})
        qru['sections'].append({"title":tr,"icon":icon,"about":ar,"questions":r_}); qen['sections'].append({"title":te,"icon":icon,"about":ae,"questions":e_})
    json.dump(qru, open(f'{A}/{sid}.quiz.json','w'), ensure_ascii=False, indent=1)
    json.dump(qen, open(f'{A}/{sid}.quiz.en.json','w'), ensure_ascii=False, indent=1)
    open(f'{A}/{sid}.txt','w').write(txt)
    print(sid, len(ru), len(en))
print('NO EN', sorted(noen))
