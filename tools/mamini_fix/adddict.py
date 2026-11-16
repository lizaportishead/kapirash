import re,json,glob,sys,os
vid=sys.argv[1]; extra=json.load(open(sys.argv[2])) if len(sys.argv)>2 else {}
cw=lambda w: re.sub(r"[^\w'-]","",w).replace('_','').lower()
def load(pat,skip):
    d={}
    for f in sorted(glob.glob(pat)):
        if skip and f.endswith('.en.json'): continue
        d.update(json.load(open(f)))
    return d
ru=load('app/assets/*.dict.json',True); en=load('app/assets/*.dict.en.json',False)
for k,(r,e) in extra.items(): ru[k]=r; en[k]=e
words={cw(w) for l in re.findall(r'--> .*\n(.*)',open(f'app/assets/{vid}.sr.vtt').read()) for w in l.split()}-{''}
for ext,src in (('dict.json',ru),('dict.en.json',en)):
    p=f'app/assets/{vid}.{ext}'
    if ext=='dict.en.json' and not os.path.exists(p): own={}
    else: own=json.load(open(p))
    n=0
    for w in sorted(words):
        if w not in own and w in src: own[w]=src[w]; n+=1
    miss=[w for w in words if w not in own]
    json.dump(own,open(p,'w'),ensure_ascii=False,indent=1)
    print(ext,'added',n,'still missing',miss)
