import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import importlib; CUES = importlib.import_module(os.environ.get('CUES','cues')).CUES
import importlib; Q = importlib.import_module(os.environ.get('QUIZ','quizzes')).Q
OUT = sys.argv[1]
for vid, d in Q.items():
    sr = ' '.join(c[2] for c in CUES[vid])
    ru = {'sections': []}; en = {'sections': []}
    secs = [('M','Смысл','Meaning','idea','Что происходит в ролике','What happens in the video'),
            ('L','Лексика','Vocabulary','translate','Слова из ролика и их перевод','Words from the video and their translations'),
            ('G','Грамматика','Grammar','puzzle','Падежи и предлоги','Cases and prepositions')]
    for k, tr, te, icon, ar, ae in secs:
        qr, qe = [], []
        for x in d[k]:
            if k == 'M':
                q_ru, q_en, o_ru, o_en, a, quote, e_ru, e_en = x
                assert quote in sr, (vid, quote)
                qr.append({"q": q_ru, "o": o_ru, "a": a, "e": f"В ролике: «{quote}» — {e_ru}"})
                qe.append({"q": q_en, "o": o_en, "a": a, "e": f"In the video: \"{quote}\" — {e_en}"})
            elif k == 'L':
                q, o_ru, o_en, a, e_ru, e_en = x
                assert q.replace('*','').lower().rstrip('.?!,') in sr.lower(), (vid, q)
                t = "Выбери перевод выделенного слова"
                qr.append({"t": t, "q": q, "o": o_ru, "a": a, "e": e_ru}); qe.append({"t": t, "q": q, "o": o_en, "a": a, "e": e_en})
            else:
                q, o, a, e_ru, e_en = x
                filled = q.replace('___', o[a])
                assert filled.lower().rstrip('.?!,') in sr.lower(), (vid, filled)
                t = "Выбери правильную форму слова"
                qr.append({"t": t, "q": q, "o": o, "a": a, "e": e_ru}); qe.append({"t": t, "q": q, "o": o, "a": a, "e": e_en})
        ru['sections'].append({"title": tr, "icon": icon, "about": ar, "questions": qr})
        en['sections'].append({"title": te, "icon": icon, "about": ae, "questions": qe})
    json.dump(ru, open(f"{OUT}/{vid}.quiz.json", 'w'), ensure_ascii=False, indent=1)
    json.dump(en, open(f"{OUT}/{vid}.quiz.en.json", 'w'), ensure_ascii=False, indent=1)
    print(vid, 'ok')
