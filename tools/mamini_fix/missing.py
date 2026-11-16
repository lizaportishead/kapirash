import re,json,glob,sys
vid=sys.argv[1]
cw=lambda w: re.sub(r"[^\w'-]","",w).replace('_','').lower()
def load(pat,skip):
    d={}
    for f in glob.glob(pat):
        if skip and f.endswith('.en.json'): continue
        d.update(json.load(open(f)))
    return d
ru=load('app/assets/*.dict.json',True); en=load('app/assets/*.dict.en.json',False)
words=set()
for l in re.findall(r'--> .*\n(.*)',open(f'app/assets/{vid}.sr.vtt').read()):
    for w in l.split():
        k=cw(w)
        if k: words.add(k)
own=json.load(open(f'app/assets/{vid}.dict.json'))
print('missing in all ru dicts:',sorted(w for w in words if w not in ru))
print('missing in en:',sorted(w for w in words if w in ru and w not in en))
print('not in own dict:',len([w for w in words if w not in own]))
