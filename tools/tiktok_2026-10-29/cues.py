# (start, end, sr, ru, en); a segment is split between its sentences in proportion to their length
CUES = {}
def seg(a, b, parts):
    tot = sum(len(p[0]) for p in parts); t = a; out = []
    for p in parts:
        d = (b - a) * len(p[0]) / tot
        out.append((round(t, 2), round(t + d, 2), p[0], p[1], p[2])); t += d
    return out
def clip(i, *segs):
    CUES[i] = [c for s in segs for c in s]

def L(a, b, sr, ru, en): return [(a, b, sr, ru, en)]

clip('7686443929889180948',
 L(0.0, 2.68, "Postavio sam crni telefon u centru grada.", "Я поставил чёрный телефон в центре города.", "I put a black phone in the city centre."),
 L(2.9, 6.9, "Videćemo da li će neko skupiti dovoljno hrabrosti da podigne slušalicu.", "Посмотрим, наберётся ли у кого-нибудь смелости снять трубку.", "We will see whether anyone gathers enough courage to pick up the receiver."),
 L(7.14, 9.32, "Ljudi su prolazili i začuđeno gledali.", "Люди проходили мимо и удивлённо смотрели.", "People walked past and looked on in surprise."),
 L(9.44, 12.28, "Ali niko još nema hrabrosti da podigne slušalicu.", "Но ни у кого пока не хватает смелости снять трубку.", "But nobody has the courage yet to pick up the receiver."),
 L(12.5, 14.44, "Izgleda da ipak nekoga zanima.", "Похоже, всё-таки кому-то интересно.", "It looks like somebody is interested after all."),
 L(14.64, 16.58, "Od ovog trenutka igra je počela.", "С этого момента игра началась.", "From this moment the game has begun."),
 L(16.84, 19.26, "Negde u centru grada nalazi se žuti kofer.", "Где-то в центре города находится жёлтый чемодан.", "Somewhere in the city centre there is a yellow suitcase."),
 L(19.54, 22.12, "Imaš minut vremena da ga pronađeš. Srećno.", "У тебя есть минута, чтобы его найти. Удачи.", "You have a minute to find it. Good luck."),
 L(22.42, 23.92, "Ajde vamo, ajde vamo, ajde vamo.", "Давай сюда, давай сюда, давай сюда.", "Come on over here, over here, over here."),
 L(30.0, 32.8, "Evo tu je, evo da vidimo šta imamo.", "Вот он, посмотрим, что у нас тут.", "Here it is, let's see what we have."),
 L(32.8, 36.8, "Tvoj sledeći zadatak je da pronađeš Luku Averića. Srećno.", "Твоё следующее задание — найти Луку Аверича. Удачи.", "Your next task is to find Luka Averić. Good luck."),
 L(36.8, 39.0, "Rate, jesi li video Luku Averića? Tiktokera.", "Рато, ты видел Луку Аверича? Тиктокера.", "Rato, have you seen Luka Averić? The TikToker."),
 L(39.0, 41.0, "Ajde, tražimo ga svi.", "Давай, мы все его ищем.", "Come on, we are all looking for him."),
 L(41.0, 42.4, "A sakrio se sigurno negde.", "А он наверняка где-то спрятался.", "And he has surely hidden somewhere."),
 L(42.4, 43.8, "Pa naći ćemo ga negde.", "Ну, найдём его где-нибудь.", "Well, we will find him somewhere."),
 L(43.8, 45.8, "Da li ste negde videli Luku? Treba ga naći.", "Вы не видели где-нибудь Луку? Его нужно найти.", "Have you seen Luka anywhere? We need to find him."),
 L(53.4, 55.4, "Jel može za vas jedan buket cveća?", "Можно вам букет цветов?", "May I give you a bouquet of flowers?"),
 L(55.4, 56.6, "E, da ste živi i zdravi.", "О, будьте живы и здоровы.", "Oh, may you live long and be healthy."),
 L(57.6, 59.3, "Da li me možda pratiš na društvenim mrežama?", "Ты, может быть, подписан на меня в соцсетях?", "Do you maybe follow me on social media?"),
 L(59.3, 61.9, "Sad da, ja iskreno ne, do danas.", "Теперь да, а раньше, честно, нет — до сегодняшнего дня.", "Now yes, honestly not before today."),
 L(61.9, 65.4, "Pošto si rekao da me pratiš, zaslužuješ 100 evra.", "Раз ты сказал, что подписан на меня, ты заслужил 100 евро.", "Since you said you follow me, you deserve 100 euros."))

clip('7692726449782033684',
 L(0.0, 4.08, "Prva osoba koja stane i pomogne mi da zamenim gumu dobija 200 evra.", "Первый человек, который остановится и поможет мне заменить колесо, получит 200 евро.", "The first person who stops and helps me change the tyre gets 200 euros."),
 L(4.32, 7.8, "Prolazilo je baš dosta automobila, ali niko još da mi stane.", "Проехало довольно много машин, но никто ещё не остановился.", "Quite a lot of cars have passed, but nobody has stopped yet."),
 L(8.06, 9.7, "A valjda će neko uskoro da stane.", "Надеюсь, кто-нибудь скоро остановится.", "Hopefully somebody will stop soon."),
 L(10.38, 12.14, "Opa, izgleda da je neko stao.", "Опа, похоже, кто-то остановился.", "Oh, it looks like somebody has stopped."),
 L(12.16, 14.14, "Je li imate možda ovu dizalicu?", "У вас случайно нет вот этого домкрата?", "Do you happen to have this jack?"),
 L(14.6, 15.84, "Ne, ne, hvala.", "Нет, нет, спасибо.", "No, no, thanks."),
 L(15.94, 18.98, "I ovo je bilo lepo što je stao, ali nažalost nije mogao da mi pomogne.", "Это тоже было мило, что он остановился, но, к сожалению, помочь мне не смог.", "That was also nice, that he stopped, but unfortunately he could not help me."),
 L(19.16, 21.96, "A sad još čekanje dok neko ne odluči da mi pomogne.", "А теперь снова ждать, пока кто-нибудь не решит мне помочь.", "And now more waiting until somebody decides to help me."),
 L(22.72, 24.08, "I konačno. Dobar dan.", "И наконец-то. Добрый день.", "And finally. Good day."),
 L(27.5, 28.72, "Da li imate dizalicu?", "У вас есть домкрат?", "Do you have a jack?"),
 L(34.1, 36.1, "Ja sam išao iz restorana. Radite u restoranu?", "Я ехал из ресторана. Вы работаете в ресторане?", "I was coming from the restaurant. Do you work in a restaurant?"),
 L(47.1, 48.1, "Hvala vam što ste stali.", "Спасибо, что остановились.", "Thank you for stopping."),
 L(48.1, 50.1, "Nema na čemu, Luka.", "Не за что, Лука.", "You are welcome, Luka."),
 L(50.1, 51.1, "Hajde da vas počastim.", "Давайте я вас угощу.", "Let me treat you."),
 L(53.1, 54.1, "Ovo je pomoć.", "Это помощь.", "This is help."),
 L(55.1, 57.1, "Ali ovo je zahvalnost za tu pomoć.", "А это благодарность за эту помощь.", "But this is gratitude for that help."),
 L(66.54, 70.86, "I kad dođem na ručak kod vas u restoran, vi me počastite, može?", "И когда я приду к вам в ресторан на обед, вы угостите меня, хорошо?", "And when I come to your restaurant for lunch, you will treat me, okay?"),
 L(75.66, 78.54, "I mnogo ste pozitivni i nasmejani.", "И вы очень позитивные и улыбчивые.", "And you are very positive and smiling."),
 L(81.3, 82.1, "Dogovoreno.", "Договорились.", "Agreed."),
 L(82.1, 82.98, "Hvala vam puno.", "Большое вам спасибо.", "Thank you very much."))

clip('7694330387035704596',
 L(0.0, 5.34, "Svako ko sedne na fotelju i odgovori na par pitanja, može izabrati neku od vrednih nagrada.", "Каждый, кто сядет в кресло и ответит на пару вопросов, может выбрать один из ценных призов.", "Anyone who sits in the armchair and answers a couple of questions can choose one of the valuable prizes."),
 L(7.44, 9.16, "Šta je za vas udobnost?", "Что для вас значит уют?", "What is comfort for you?"),
 L(9.4, 11.22, "Kada sednem i popijem svoju kafu.", "Когда я сажусь и пью свой кофе.", "When I sit down and drink my coffee."),
 L(11.4, 13.48, "Koja osoba vama daje osjećaj doma?", "Какой человек дарит вам ощущение дома?", "Which person gives you the feeling of home?"),
 L(13.7, 16.02, "Porodica. Cijela moja porodica. Moja deca.", "Семья. Вся моя семья. Мои дети.", "Family. My whole family. My children."),
 L(16.16, 18.8, "Gdje god da sam sa njima, osjećam se kao da sam kod kuće.", "Где бы я ни был с ними, я чувствую себя как дома.", "Wherever I am with them, I feel as if I am at home."),
 L(18.9, 22.18, "Koliko dugo možete da provedete u pidžami, a da vas ne grize savjest?", "Как долго вы можете провести в пижаме, чтобы вас не мучила совесть?", "How long can you spend in pyjamas without feeling guilty?"),
 L(22.24, 23.72, "Biste li mogli biti u pidžami čitav dan?", "Могли бы вы провести в пижаме целый день?", "Could you stay in pyjamas the whole day?"),
 L(24.38, 29.14, "Bih. Svet bi bio udobnije mesto kada bi ljudi mogli po ceo dan da budu u pidžamama.", "Да. Мир был бы уютнее, если бы люди могли весь день ходить в пижамах.", "Yes. The world would be a more comfortable place if people could be in pyjamas all day."),
 L(30.64, 33.34, "Da li mislite da svetu treba više udobnosti i zašto?", "Как вы думаете, нужно ли миру больше уюта и почему?", "Do you think the world needs more comfort and why?"),
 L(33.34, 36.34, "Naravno. Treba nam više ljubavi, pažnje.", "Конечно. Нам нужно больше любви, внимания.", "Of course. We need more love, more attention."),
 L(39.94, 43.14, "Treba nam više udobnosti da bismo bili opušteni.", "Нам нужно больше уюта, чтобы быть расслабленными.", "We need more comfort so that we can be relaxed."),
 L(43.14, 45.64, "Imamo jedan mali poklon za vas, možete da izaberete.", "У нас есть для вас маленький подарок, можете выбрать.", "We have a little gift for you, you can choose."),
 L(47.14, 49.94, "Poklon kartica, Extreme Intimo.", "Подарочная карта, Extreme Intimo.", "A gift card, Extreme Intimo."),
 L(49.94, 51.94, "Tri hiljade dinara.", "Три тысячи динаров.", "Three thousand dinars."),
 L(55.14, 57.44, "Pidžama. Pidžama. Extreme Intimo.", "Пижама. Пижама. Extreme Intimo.", "Pyjamas. Pyjamas. Extreme Intimo."),
 L(57.44, 63.88, "Izgleda da udobnost za svakoga znači nešto drugo, ali jedno je sigurno: svetu treba više udobnosti.", "Похоже, уют для каждого значит что-то своё, но одно ясно: миру нужно больше уюта.", "It seems comfort means something different to everyone, but one thing is certain: the world needs more comfort."))

clip('7695838371725249812',
 L(0.0, 0.7, "Izvinite.", "Извините.", "Excuse me."),
 L(2.8, 4.4, "Da li mogu da vas pitam nešto?", "Можно вас кое о чём спросить?", "May I ask you something?"),
 L(5.6, 7.9, "Da li vam baterija na telefonu traje tri dana?", "Батареи вашего телефона хватает на три дня?", "Does your phone battery last three days?"),
 L(8.2, 8.6, "Pa ne.", "Ну нет.", "Well, no."),
 L(10.1, 12.2, "Imate li par minuta da vas malo ukradem?", "Есть пара минут, чтобы я вас немного украл?", "Do you have a couple of minutes for me to steal you for a bit?"),
 L(17.3, 18.0, "Ja sam Luka.", "Я Лука.", "I am Luka."),
 L(18.7, 20.4, "Koliko dugo već radite u kuhinji?", "Как давно вы уже работаете на кухне?", "How long have you been working in the kitchen?"),
 L(20.5, 22.1, "Četvrta godina.", "Четвёртый год.", "The fourth year."),
 L(22.1, 23.1, "Ima li posla puno?", "Много работы?", "Is there a lot of work?"),
 L(23.3, 25.3, "Ima posla koliko hoćeš.", "Работы хоть отбавляй.", "There is as much work as you like."),
 L(25.4, 26.8, "Sad imam jedno iznenađenje za vas.", "Сейчас у меня для вас есть сюрприз.", "Now I have a surprise for you."),
 L(27.1, 28.1, "Može?", "Можно?", "Okay?"),
 L(28.68, 35.68, "Pošto ste rekli da vam baterija ne traje tri dana, spremili smo vam nov telefon, Redmi Note 17.", "Раз вы сказали, что батареи вам не хватает на три дня, мы приготовили вам новый телефон — Redmi Note 17.", "Since you said your battery does not last three days, we have prepared a new phone for you, the Redmi Note 17."),
 L(35.68, 40.68, "Njemu baterija traje čak do tri dana, i otporan je i na udarce i na prašinu.", "У него батареи хватает даже на три дня, и он устойчив и к ударам, и к пыли.", "Its battery lasts up to three days, and it is resistant to both knocks and dust."),
 L(40.68, 44.68, "Pohvalili su vas da ste vredni, da ste radni.", "Вас похвалили, сказали, что вы трудолюбивы и работящи.", "They praised you, saying that you are hard-working and diligent."),
 L(45.68, 48.68, "Oooo, što je lepo upakovano.", "О-о-о, как красиво упаковано.", "Ooooh, how nicely it is wrapped."),
 L(48.68, 49.68, "Ludilo.", "Безумие!", "Crazy!"),
 L(52.68, 53.68, "Prelep je.", "Он прекрасен.", "It is gorgeous."),
 L(53.68, 55.68, "Nisam se nadala telefonu.", "Я не рассчитывала на телефон.", "I did not expect a phone."),
 L(57.26, 58.84, "Ne, ništa, baš ti hvala, Luka.", "Нет-нет, правда, большое тебе спасибо, Лука.", "No, it is nothing, thank you so much, Luka."))
