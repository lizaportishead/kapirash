import re,sys,glob,json,os
vid=sys.argv[1]; A='app/assets/'
def t(s):
    h,m,x=s.split(':');return int(h)*3600+int(m)*60+float(x)
def ts(x):
    ms=round(x*1000);h,ms=divmod(ms,3600000);m,ms=divmod(ms,60000);s,ms=divmod(ms,1000);return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"
def rd(ext):
    p=f'{A}{vid}.{ext}.vtt'
    if not os.path.exists(p): return None
    return [[t(a),t(b),c] for a,b,c in re.findall(r'(\d+:\d+:\d+\.\d+) --> (\d+:\d+:\d+\.\d+)\n(.*)',open(p).read())]
sr,ru,en=rd('sr'),rd('ru'),rd('en')
assert len(sr)==len(ru) and (en is None or len(en)==len(sr))
if os.environ.get('RESTORE'): pass
rows=[[sr[k][0],sr[k][1],sr[k][2],ru[k][2],en[k][2] if en else ''] for k in range(len(sr))]
ex=[]
for l in open(f'tools/mamini_fix/extra_{vid}.txt',encoding='utf-8'):
    if l.strip():
        a,b,s,r,e=l.rstrip('\n').split('|'); ex.append([float(a),float(b),s,r,e])
have={r[2] for r in rows}
rows=[r for r in rows if True]; added=0
for a,b,s,r,e in ex:
    if s in have: continue
    ov=[x for x in rows if x[0]<b-0.2 and x[1]>a+0.2]
    if ov:  # trim extra to fit between neighbours; drop if no room
        prev=max([x[1] for x in rows if x[1]<=a+0.2] or [0]); nxt=min([x[0] for x in rows if x[0]>=b-0.2] or [1e9])
        # existing cue overlaps: shorten the existing cue
        for x in ov:
            if x[0]<a: x[1]=min(x[1],a-0.05)
            elif x[1]>b: x[0]=max(x[0],b+0.05)
        ov=[x for x in rows if x[0]<b-0.2 and x[1]>a+0.2 and x[0]>=a-0.2]
        if ov: print('skip overlap',a,s); continue
    rows.append([a,b,s,r,e]); added+=1
rows.sort(key=lambda x:x[0])
for i in range(len(rows)-1):
    if rows[i][1]>rows[i+1][0]: rows[i][1]=round(max(rows[i][0]+0.3,rows[i+1][0]-0.05),2)
for idx,ext in ((2,'sr'),(3,'ru'),(4,'en')):
    if ext=='en' and not en: continue
    out=['WEBVTT','']
    for n,c in enumerate(rows,1): out+=[str(n),f"{ts(c[0])} --> {ts(c[1])}",c[idx],'']
    open(f'{A}{vid}.{ext}.vtt','w').write('\n'.join(out))
print(vid,'added',added,'total',len(rows))
