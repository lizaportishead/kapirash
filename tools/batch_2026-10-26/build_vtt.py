import sys, os, re, json, glob
sys.path.insert(0, os.path.dirname(__file__))
import importlib; CUES = importlib.import_module(os.environ.get('CUES','cues')).CUES
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
def ts(t):
    ms = round(t*1000); h, ms = divmod(ms, 3600000); m, ms = divmod(ms, 60000); s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"
for vid, cues in CUES.items():
    for idx, ext in ((2,'sr'),(3,'ru'),(4,'en')):
        out = ["WEBVTT", ""]
        for n, c in enumerate(cues, 1):
            out += [str(n), f"{ts(c[0])} --> {ts(c[1])}", c[idx], ""]
        open(f"{OUT}/{vid}.{ext}.vtt", "w").write("\n".join(out))
# words missing from existing dictionaries
known = {}; known_en = {}
for f in glob.glob('app/assets/*.dict.json'):
    if f.endswith('.en.json'): continue
    known.update(json.load(open(f)))
for f in glob.glob('app/assets/*.dict.en.json'):
    known_en.update(json.load(open(f)))
cw = lambda w: re.sub(r"[^\p{L}\p{N}'-]".replace(r'\p{L}','^\W_').replace(r'\p{N}',''), '', w) if False else re.sub(r"[^\w'-]", '', w).replace('_','')
for vid, cues in CUES.items():
    words = set()
    for c in cues:
        for w in c[2].split():
            k = cw(w).lower()
            if k: words.add(k)
    miss = sorted(w for w in words if w not in known)
    print(vid, len(words), 'missing', len(miss))
    open(f"{OUT}/{vid}.missing.txt","w").write("\n".join(miss)+"\n")
