import json, os
D = os.path.dirname(os.path.abspath(__file__))
SEG = json.load(open('/private/tmp/claude-501/-Users-elizavetamatveeva-projects-kapiras-player/8a8c6d9f-f3aa-496e-88c2-4e7904f5a139/scratchpad/w/w.json'))
rows = []
for l in open(os.path.join(D, 'an.txt'), encoding='utf-8'):
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
rows.sort()
CUES = {'VAI5GxslifI': rows}
