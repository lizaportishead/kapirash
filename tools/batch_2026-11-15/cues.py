import json, os
D = os.path.dirname(os.path.abspath(__file__))
def build(vid, fn):
    seg = json.load(open(os.path.join(D, vid + '.json')))
    rows = []
    for l in open(os.path.join(D, fn), encoding='utf-8'):
        if not l.strip(): continue
        rng, sr, ru, en = l.rstrip('\n').split('|')
        x, y = rng.split('-') if '-' in rng else (rng, rng)
        a = float(x[1:]) if x[0] == 't' else seg[int(x)][0]
        b = float(y[1:]) if y[0] == 't' else seg[int(y)][1]
        S, R, E = [z.split(' ¦ ') for z in (sr, ru, en)]
        tot = sum(len(s) for s in S); t = a
        for s, r, e in zip(S, R, E):
            d = (b - a) * len(s) / tot
            rows.append((round(t, 2), round(t + d - 0.05, 2), s, r, e)); t += d
    rows.sort()
    # no overlaps
    for i in range(len(rows) - 1):
        if rows[i][1] > rows[i+1][0]:
            rows[i] = (rows[i][0], round(rows[i+1][0] - 0.05, 2)) + rows[i][2:]
    return rows
CUES = {'K_nn3jYg2_Y': build('K_nn3jYg2_Y', 'mm2.txt'), 'lxG7zm8exaM': build('lxG7zm8exaM', 'mm3.txt')}
