import json,re,sys
def t(s):
    h,m,x=s.split(':');return int(h)*3600+int(m)*60+float(x)
M={'а':'a','б':'b','в':'v','г':'g','д':'d','ђ':'đ','е':'e','ж':'ž','з':'z','и':'i','ј':'j','к':'k','л':'l','љ':'lj','м':'m','н':'n','њ':'nj','о':'o','п':'p','р':'r','с':'s','т':'t','ћ':'ć','у':'u','ф':'f','х':'h','ц':'c','ч':'č','џ':'dž','ш':'š'}
def lat(s): return ''.join(M.get(c,M.get(c.lower(),c)) for c in s)
def toks(s): return set(re.findall(r"\w+",lat(s).lower()))
i=sys.argv[1]
cues=[(t(a),t(b),c) for a,b,c in re.findall(r'(\d+:\d+:\d+\.\d+) --> (\d+:\d+:\d+\.\d+)\n(.*)',open(f'app/assets/{i}.sr.vtt').read())]
for k,s in enumerate(json.load(open(f'tools/mamini_fix/{i}.v3.json'))):
    if len(s[2])<5 or s[3]>0.6: continue
    near=set()
    for a,b,c in cues:
        if a-30<=s[0]<=b+30: near|=toks(c)
    w=toks(s[2])
    if w and len(w&near)/len(w)<0.5: print(k,s[0],s[1],lat(s[2]))
