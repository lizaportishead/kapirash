import re,json,sys
A='/private/tmp/claude-501/-Users-elizavetamatveeva--claude-spares-spare-uskiet/8d08f207-2e3c-4db2-9be5-013909a297d4/scratchpad/audio/'
def t(s):
    h,m,x=s.split(':');return int(h)*3600+int(m)*60+float(x)
def toks(s): return set(re.findall(r"\w+",s.lower()))
res={}
for i in ['bjN_HyuFWj0','K_nn3jYg2_Y','lxG7zm8exaM','Haw-E4vxBYg','f1qsclLQyzQ','vE6iiAVoD3c']:
    cues=[(t(a),t(b),c) for a,b,c in re.findall(r'(\d+:\d+:\d+\.\d+) --> (\d+:\d+:\d+\.\d+)\n(.*)',open(f'app/assets/{i}.sr.vtt').read())]
    new=json.load(open(A+i+'.nov.json'))
    miss=[]
    for s in new:
        if len(s[2])<8 or s[3]>0.6 or 'pratite' in s[2]: continue
        near=set()
        for a,b,c in cues:
            if a-25<=s[0]<=b+25: near|=toks(c)
        w=toks(s[2])
        if w and len(w&near)/len(w)<0.5: miss.append((s[0],s[1]))
    reg=[]
    for a,b in miss:
        a=max(0,a-2);b=b+2
        if reg and a<=reg[-1][1]+6: reg[-1][1]=max(reg[-1][1],b)
        else: reg.append([a,b])
    res[i]=reg
    print(i,len(miss),'segs',len(reg),'regions %.0f s'%sum(b-a for a,b in reg))
json.dump(res,open('tools/mamini_fix/regions.json','w'))
