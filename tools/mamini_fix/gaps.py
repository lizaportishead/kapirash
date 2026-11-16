import json,re,sys
vid=sys.argv[1]
A='/private/tmp/claude-501/-Users-elizavetamatveeva--claude-spares-spare-uskiet/8d08f207-2e3c-4db2-9be5-013909a297d4/scratchpad/audio/'
def t(s):
    h,m,x=s.split(':');return int(h)*3600+int(m)*60+float(x)
cues=[(t(a),t(b),c) for a,b,c in re.findall(r'(\d+:\d+:\d+\.\d+) --> (\d+:\d+:\d+\.\d+)\n(.*)',open(f'app/assets/{vid}.sr.vtt').read())]
segs=[s for s in json.load(open(A+vid+'.nov.json')) if s[3]<0.6 and len(s[2])>=8 and 'pratite' not in s[2]]
segs+=[s for s in json.load(open(f'tools/mamini_fix/{vid}.v3.json')) if s[3]<0.6 and len(s[2])>=8 and 'pratite' not in s[2]]
segs.sort()
M={'а':'a','б':'b','в':'v','г':'g','д':'d','ђ':'đ','е':'e','ж':'ž','з':'z','и':'i','ј':'j','к':'k','л':'l','љ':'lj','м':'m','н':'n','њ':'nj','о':'o','п':'p','р':'r','с':'s','т':'t','ћ':'ć','у':'u','ф':'f','х':'h','ц':'c','ч':'č','џ':'dž','ш':'š'}
def toks(x): return set(re.findall(r"\w+",''.join(M.get(c,M.get(c.lower(),c)) for c in x).lower()))
def known(s):
    near=set()
    for a,b,c in cues:
        if a-30<=s[0]<=b+30: near|=toks(c)
    w=toks(s[2]); return bool(w) and len(w&near)/len(w)>=0.5
segs=[s for s in segs if not known(s)]
# keep speech spans that lie in a gap between cues (>=1.2s of uncovered time)
gaps=[]
for s in segs:
    a,b=s[0],min(s[1],s[0]+8)
    if any(x<b-0.3 and y>a+0.3 for x,y,_ in cues): continue
    if gaps and a<=gaps[-1][1]+2.5: gaps[-1][1]=max(gaps[-1][1],b)
    else: gaps.append([a,b])
out=[]
for a,b in gaps:
    prev=max([y for x,y,_ in cues if y<=a+0.3] or [0]); nxt=min([x for x,y,_ in cues if x>=b-0.3] or [1e9])
    a=max(a,prev+0.05); b=min(b,nxt-0.05)
    if b-a>=1.5: out.append((round(a,2),round(min(b,a+6),2)))
open(f'tools/mamini_fix/extra_gaps_{vid}.txt','w').write('\n'.join(f'{a}|{b}|[…]|[неразборчиво]|[unintelligible]' for a,b in out)+'\n')
print(vid,len(out),'placeholders, total %.0f s'%sum(b-a for a,b in out))
