import json, os
D = os.path.dirname(os.path.abspath(__file__))
SEG = json.load(open('/private/tmp/claude-501/-Users-elizavetamatveeva-projects-kapiras-player/83c85825-077c-4865-8049-3469b137d9aa/scratchpad/dnevnik/ep.json'))
def load(fn):
    rows = []
    for l in open(os.path.join(D, fn), encoding='utf-8'):
        if not l.strip(): continue
        rng, sr, ru, en = l.rstrip('\n').split('|')
        i, j = map(int, rng.split('-'))
        a, b = SEG[i][0], SEG[j][1]
        S, R, E = [x.split(' ¦ ') for x in (sr, ru, en)]
        assert len(S) == len(R) == len(E), rng
        tot = sum(len(s) for s in S); t = a
        for s, r, e in zip(S, R, E):
            d = (b - a) * len(s) / tot
            rows.append((round(t, 2), round(t + d, 2), s, r, e)); t += d
    return rows
CUES = {'dnevnik-studentski-zivot': load('dn.txt')}
