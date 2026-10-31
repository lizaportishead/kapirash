import sys
CASE={'nom':('им.','nom.'),'gen':('род.','gen.'),'dat':('дат.','dat.'),'acc':('вин.','acc.'),'ins':('тв.','instr.'),'loc':('мест.','loc.'),'voc':('зв.','voc.')}
SIMPLE={'sg':('ед. ч.','sg.'),'pl':('мн. ч.','pl.'),'m':('м. р.','masc.'),'f':('ж. р.','fem.'),'n':('ср. р.','neut.'),
 'inf':('инфинитив','infinitive'),'pr1s':('наст. вр. 1 л. ед. ч.','present 1st sg.'),'pr2s':('наст. вр. 2 л. ед. ч.','present 2nd sg.'),
 'pr3s':('наст. вр. 3 л. ед. ч.','present 3rd sg.'),'pr1p':('наст. вр. 1 л. мн. ч.','present 1st pl.'),'pr3p':('наст. вр. 3 л. мн. ч.','present 3rd pl.'),
 'pr2p':('наст. вр. 2 л. мн. ч.','present 2nd pl.'),
 'ptm':('прош. вр. м. р.','past masc.'),'ptf':('прош. вр. ж. р.','past fem.'),'ptn':('прош. вр. ср. р.','past neut.'),
 'ptp':('прош. вр. мн. ч.','past pl.'),'pas':('страд. прич.','passive'),'comp':('сравн. ст.','comparative'),'superl':('превосх. ст.','superlative'),'adv':('наречие','adverb'),
 'fut3s':('буд. вр. 3 л. ед. ч.','future 3rd sg.'),'fut2s':('буд. вр. 2 л. ед. ч.','future 2nd sg.'),'fut1s':('буд. вр. 1 л. ед. ч.','future 1st sg.'),'imp2s':('повел. 2 л. ед. ч.','imperative 2nd sg.'),'imp1p':('повел. 1 л. мн. ч.','imperative 1st pl.'),
 'imp2p':('повел. 2 л. мн. ч.','imperative 2nd pl.'),'perf':('сов. вид','perfective')}
def conv(code):
    ru=[];en=[]
    for t in code.split():
        if all(p in CASE for p in t.split('/')):
            ps=t.split('/')
            ru.append('/'.join(CASE[p][0] for p in ps)+' п.'); en.append('/'.join(CASE[p][1] for p in ps))
        elif all((p in SIMPLE or p in CASE) for p in t.split('/')):
            ps=t.split('/')
            ru.append('/'.join((SIMPLE[p][0] if p in SIMPLE else CASE[p][0]+' п.') for p in ps)); en.append('/'.join((SIMPLE[p][1] if p in SIMPLE else CASE[p][1]) for p in ps))
        else:
            raise SystemExit('bad token '+t)
    return ' '.join(ru), ' '.join(en)
for fn in sys.argv[2:]:
    pass
out=[]
for fn in sys.argv[2:]:
  for l in open(fn,encoding='utf-8'):
    if not l.strip(): continue
    w,ru,en,lem,lru,len_,code=l.rstrip('\n').split('|')
    # allow free text in parentheses at end: "(...)"
    extra=''
    if '(' in code:
        i=code.index('('); extra=code[i:]; code=code[:i].strip()
    cr,ce=conv(code) if code and code not in('number',) else ('','')
    nr=f"{lem} — {lru}"+(f"; {cr}" if cr else '')+(f" {extra}" if extra else '')
    ne=f"{lem} — {len_}"+(f"; {ce}" if ce else '')+(f" {extra}" if extra else '')
    out.append('\t'.join([w,ru,nr,en,ne]))
open(sys.argv[1],'w',encoding='utf-8').write('\n'.join(out)+'\n')
print(len(out))
