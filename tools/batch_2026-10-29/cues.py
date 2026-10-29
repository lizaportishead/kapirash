import os
CUES = {}
def load(vid, fn):
    rows = []
    for l in open(os.path.join(os.path.dirname(__file__), fn), encoding='utf-8'):
        if not l.strip(): continue
        a, b, sr, ru, en = l.rstrip('\n').split('|')
        a, b = float(a), float(b)
        S, R, E = ([p.strip() for p in x.split('¦')] for x in (sr, ru, en))
        assert len(S) == len(R) == len(E), (a, sr)
        tot = sum(len(s) for s in S); t = a
        for s, r, e in zip(S, R, E):
            d = (b - a) * len(s) / tot
            rows.append((round(t, 2), round(t + d, 2), s, r, e)); t += d
    CUES[vid] = rows
load('RCWmyQdrqRo', 'tg.txt')
