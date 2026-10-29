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
def P(sr, ru, en): return (sr, ru, en)

clip('7619384555262299412',
 seg(0.0, 9.0, [P("Izvinite, koliko je ova ogrlica?", "Извините, сколько стоит это ожерелье?", "Excuse me, how much is this necklace?"), P("Ta ogrlica vam je 800.", "Это ожерелье — 800.", "That necklace is 800 for you."), P("Aha, ja imam samo 1000, je li to okej?", "Ага, у меня только 1000, ничего?", "I see, I only have 1000, is that okay?")]),
 seg(9.0, 13.0, [P("Nema problema, imam ja da vam vratim. Evo 200.", "Без проблем, у меня есть сдача. Вот 200.", "No problem, I have change to give you back. Here is 200.")]),
 seg(13.0, 23.0, [P("A ovaj prsten? Koliko je ovaj prsten?", "А это кольцо? Сколько стоит это кольцо?", "And this ring? How much is this ring?"), P("Taj je 300. Evo, izvolite.", "Оно 300. Вот, пожалуйста.", "That one is 300. Here you go.")]),
 L(23.0, 25.22, "Izvinite, dajte mi još 100.", "Извините, дайте мне ещё 100.", "Excuse me, give me another 100."),
 L(25.66, 27.74, "Pa nije tačno, jel imate 1200?", "Но это неверно, у вас есть 1200?", "But that is not right, do you have 1200?"),
 L(29.06, 30.14, "Imam.", "Есть.", "I do."),
 L(31.24, 34.16, "Ovo ste rekli da je 800, ovo ste rekli da je 300.", "Это вы сказали 800, а это — 300.", "You said this one is 800, and this one is 300."),
 L(34.66, 37.12, "To je 1100 i tih 100 vas ja častim.", "Это 1100, и эти 100 я вас угощаю.", "That is 1100 and I treat you to those 100."),
 L(37.6, 40.68, "Hvala, prijatno. Ok, prijatno.", "Спасибо, всего хорошего. Хорошо, всего хорошего.", "Thank you, take care. Okay, take care."))

clip('7641260521114799380',
 L(0.66, 2.12, "Koliko je ova narukvica?", "Сколько стоит этот браслет?", "How much is this bracelet?"),
 L(2.38, 3.78, "Narukvica je hiljadu.", "Браслет стоит тысячу.", "The bracelet is a thousand."),
 L(4.2, 5.78, "A može neki popust?", "А можно какую-нибудь скидку?", "Can I get a discount?"),
 L(6.54, 9.66, "A pa zavisi koliko komada planirate da uzmete.", "Ну, зависит от того, сколько штук вы планируете взять.", "Well, it depends on how many pieces you plan to take."),
 L(10.2, 11.36, "Pa jedno.", "Ну, одну.", "Well, one."),
 L(12.08, 13.26, "Pa onda nema popusta.", "Тогда скидки нет.", "Then there is no discount."),
 L(13.92, 14.46, "Zašto?", "Почему?", "Why?"),
 L(14.96, 17.46, "Pa zato što je cena jedne narukvice hiljadu.", "Потому что цена одного браслета — тысяча.", "Because the price of one bracelet is a thousand."),
 L(18.6, 19.72, "Evo, može za 700.", "Ладно, можно за 700.", "Fine, it can be 700."),
 L(20.54, 23.7, "Stvarno, nije moja roba. Ja sam samo radnik ovde.", "Правда, это не мой товар. Я здесь просто работник.", "Really, it is not my merchandise. I am just a worker here."),
 L(24.18, 24.78, "Ne mogu.", "Не могу.", "I can't."),
 L(25.68, 26.86, "750 i to je to.", "750, и всё.", "750 and that's it."),
 L(27.82, 29.9, "Žao mi je, stvarno ne mogu.", "Мне жаль, правда не могу.", "I am sorry, I really can't."),
 L(29.9, 32.88, "Ma, 800 ni dinar više, tako sam rekla.", "Да ладно, 800, ни динара больше, я так сказала.", "Come on, 800, not a dinar more, that is what I said."),
 L(34.72, 36.44, "1300, molim.", "1300, пожалуйста.", "1300, please."),
 L(38.94, 39.94, "Pa, kako sad to?", "Как это сейчас?", "Well, how come now?"),
 L(40.46, 41.66, "Eto tako, 1300.", "Вот так, 1300.", "Just like that, 1300."),
 L(42.6, 45.78, "Pa, rekli ste da nije vaša roba, vi ste samo radnik.", "Но вы же сказали, что это не ваш товар, вы просто работник.", "But you said it is not your merchandise, you are just a worker."),
 L(47.52, 48.96, "Dobro, shvatila sam.", "Хорошо, я поняла.", "Okay, I understood."),
 L(49.26, 51.02, "Prava cena narukvice je 1000.", "Настоящая цена браслета — 1000.", "The real price of the bracelet is 1000."),
 L(51.64, 53.86, "1000 je narukvica i to je to, razumem.", "1000 за браслет, и всё, понимаю.", "1000 for the bracelet and that's it, I understand."))

clip('7700262799892696340',
 L(0.0, 1.2, "Da li voliš svog bivšeg?", "Ты любишь своего бывшего?", "Do you love your ex?"),
 L(1.3, 2.7, "Da. Voliš? Da.", "Да. Любишь? Да.", "Yes. You do? Yes."),
 L(2.9, 5.0, "Ajde, nazovi ga i pitaj ga da se pomirite.", "Давай, позвони ему и предложи помириться.", "Come on, call him and ask him to make up."),
 L(5.4, 7.1, "Dobro. Hoćeš? Hoću.", "Хорошо. Хочешь? Хочу.", "Okay. Do you want to? I do."),
 L(7.2, 8.3, "Pre koliko ste raskinuli?", "Как давно вы расстались?", "How long ago did you break up?"),
 L(8.4, 9.2, "Pre dve nedelje.", "Две недели назад.", "Two weeks ago."),
 L(9.3, 12.2, "Gagi sastavlja veze, najviše rastavlja.", "Гаги соединяет пары, но больше разлучает.", "Gagi puts relationships together, mostly he breaks them up."),
 L(12.5, 14.1, "Halo. Halo.", "Алло. Алло.", "Hello. Hello."),
 L(14.3, 17.0, "Ajde da se pomirimo, razmišljala sam dugo o tome.", "Давай помиримся, я долго об этом думала.", "Let's make up, I have been thinking about it for a long time."),
 L(17.3, 20.3, "A zar nisi ti rekla da više ne pričamo?", "А разве не ты сказала, что мы больше не разговариваем?", "Didn't you say that we don't talk anymore?"),
 L(20.4, 23.8, "Pa da, ali razmišljala sam malo i mislim da sam napravila grešku.", "Да, но я немного подумала и считаю, что совершила ошибку.", "Yes, but I thought a bit and I think I made a mistake."),
 L(28.1, 29.4, "Ozbiljno? Da.", "Серьёзно? Да.", "Seriously? Yes."),
 L(29.9, 31.8, "Dobro, ajde, volim te, čao.", "Хорошо, давай, люблю тебя, пока.", "Okay, come on, I love you, bye."),
 L(32.2, 32.9, "Ajde, čao.", "Давай, пока.", "Come on, bye."),
 L(33.0, 34.0, "Ma idemo bre!", "Ну всё, поехали!", "Come on, let's go!"),
 L(35.5, 38.0, "Pa moram ja da sastavim neki par, ne mogu samo da rastavljam.", "Мне же надо кого-то свести, не могу только разлучать.", "Well, I have to put some couple together, I can't only break them up."),
 L(38.1, 39.5, "Lajkujte ovaj klip i zapratite me.", "Лайкайте этот клип и подписывайтесь на меня.", "Like this clip and follow me."))

clip('7662423129767152916',
 L(0.0, 1.3, "Izvinite, jel radite još uvek?", "Извините, вы ещё работаете?", "Excuse me, are you still open?"),
 L(2.0, 4.5, "Ne, nažalost, gotovo je za danas.", "Нет, к сожалению, на сегодня всё.", "No, unfortunately, we are done for today."),
 L(5.0, 8.8, "Ah, šteta, htela sam da kupim deset ovih velikih ogrlica.", "Ах, жаль, я хотела купить десять вот этих больших ожерелий.", "Ah, a pity, I wanted to buy ten of these big necklaces."),
 L(10.6, 13.7, "Deset? Ma uđite, mislim, priđite slobodno.", "Десять? Да входите, то есть подходите, пожалуйста.", "Ten? Come in, I mean, step closer, feel free."),
 L(14.4, 15.6, "E, hvala vam puno.", "О, большое вам спасибо.", "Oh, thank you very much."),
 L(16.3, 20.5, "Deset puta hiljadu petsto, petnaest hiljada.", "Десять раз по тысяче пятьсот — пятнадцать тысяч.", "Ten times one thousand five hundred, fifteen thousand."),
 L(21.4, 23.7, "O, evo ih, velike ogrlice.", "О, вот они, большие ожерелья.", "Oh, here they are, the big necklaces."),
 L(25.5, 29.3, "Pa, to su male, od 300 dinara.", "Но это маленькие, по 300 динаров.", "But those are small ones, 300 dinars each."),
 L(30.0, 31.9, "Da, da, na njih sam mislila.", "Да-да, именно о них я и думала.", "Yes, yes, those are the ones I meant."),
 L(32.4, 35.1, "I jao, koliko veliki izbor.", "Ой, какой большой выбор.", "Oh, what a big selection."),
 L(35.4, 37.5, "Bolje sedite vi, potrajaće ovo.", "Лучше присядьте, это займёт время.", "You had better sit down, this will take a while."),
 L(39.2, 41.3, "Slobodno, ne žurite.", "Не торопитесь, пожалуйста.", "Take your time, don't rush."))
