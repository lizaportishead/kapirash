import os
CUES = {}
def load(vid, fn):
    rows = []
    for l in open(os.path.join(os.path.dirname(__file__), fn), encoding='utf-8'):
        if not l.strip(): continue
        a, b, sr, ru, en = l.rstrip('\n').split('|')
        rows.append((float(a), float(b), sr, ru, en))
    CUES[vid] = rows
load('Qb-JTu0gl6k', 'qb.txt')
if os.path.exists(os.path.join(os.path.dirname(__file__), 'xlb.txt')):
    load('xlb_hJPiOGU', 'xlb.txt')
