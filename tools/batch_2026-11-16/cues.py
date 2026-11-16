import json, os
D = os.path.dirname(os.path.abspath(__file__))
def build(vid, fn):
    seg = json.load(open(os.path.join(D, vid + '.json')))
    rows = []
    for l in open(os.path.join(D, fn), encoding='utf-8'):
        if not l.strip(): continue
        rng, sr, ru, en = l.rstrip('\n').split('|')
        x, y = rng.split('-') if '-' in rng else (rng, rng)
        a = seg[int(x)][0]
        b = seg[min(int(y), len(seg)-1)+0][1] if int(y) < len(seg)-1 else seg[-1][1]
        # end = start of segment y+? use own end
        b = seg[int(y)][1]
        S, R, E = [z.split(' ¦ ') for z in (sr, ru, en)]
        assert len(S) == len(R) == len(E), (fn, rng)
        tot = sum(len(s) for s in S); t = a
        for s, r, e in zip(S, R, E):
            d = (b - a) * len(s) / tot
            rows.append((round(t, 2), round(t + d - 0.05, 2), s, r, e)); t += d
    rows = [(a, min(b, round(a + max(1.5, len(sr_)*0.075 + 1.0), 2)), sr_, r_, e_) for a, b, sr_, r_, e_ in rows]
    rows.sort()
    for i in range(len(rows) - 1):
        if rows[i][1] > rows[i+1][0]:
            rows[i] = (rows[i][0], round(max(rows[i][0]+0.3, rows[i+1][0] - 0.05), 2)) + rows[i][2:]
    return rows
CUES = {'Haw-E4vxBYg': build('Haw-E4vxBYg', 'mm4.txt'), 'f1qsclLQyzQ': build('f1qsclLQyzQ', 'mm5.txt'), 'vE6iiAVoD3c': build('vE6iiAVoD3c', 'mm6.txt')}
