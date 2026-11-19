Q = {}
def M(qr, qe, o, a, quote, er, ee): return (qr, qe, o[0], o[1], a, quote, er, ee)
def N(o): return (o, o)  # numbers: same options in both languages

# Željko — majka i ChatGPT
Q['7709554796931321106'] = {
'M': [
 ("Что мама просит включить?", "What does the mother ask to be turned on?", ["телевизор","ИИ (она зовёт его «ЛГБТ»)","радио","свет"], ["the TV","an AI (she calls it \"LGBT\")","the radio","the light"], 1, "Upali mi onaj LGBT", "включи мне этот ЛГБТ.", "turn on that LGBT for me."),
 ("Как на самом деле называется то, что ей нужно?", "What is the thing she wants really called?", ["ChatGPT","Instagram","YouTube","Netflix"], ["ChatGPT","Instagram","YouTube","Netflix"], 0, "nije LGBT nego ChatGPT", "это не ЛГБТ, а ChatGPT.", "it is not LGBT, it is ChatGPT."),
 ("Что мама отвечает, когда сын её поправляет?", "What does the mother say when her son corrects her?", ["что ошиблась","что ей всё равно: для неё это одно и то же","что не слышала","что он сам неправ"], ["that she was wrong","that it is all the same to her","that she did not hear","that he is wrong"], 1, "Meni to isto", "мне это одно и то же.", "to me it is the same."),
 ("Что Желько делает в конце?", "What does Željko do at the end?", ["включает ей ChatGPT","выходит из комнаты","звонит брату","смеётся и отказывается"], ["turns ChatGPT on for her","leaves the room","calls his brother","laughs and refuses"], 0, "Evo, palim ti", "вот, включаю тебе.", "here, I am turning it on for you."),
],
'L': [
 ("Željko, ajde upali mi onaj LGBT da ga nešto *pitam*.", ["спрошу","отвечу","куплю","запомню"], ["I ask","I answer","I buy","I remember"], 0, "Pitati — спрашивать.", "Pitati — to ask."),
 ("Ajde, ne *zanovetaj*, bre, nego mi uključi.", ["придирайся","иди","смотри","говори"], ["nag","go","look","speak"], 0, "Zanovetati — придираться, нудеть.", "Zanovetati — to nag."),
 ("Evo, palim ti, kaže se ChatGPT, *zapamti*.", ["запомни","забудь","повтори","выключи"], ["remember","forget","repeat","switch off"], 0, "Zapamtiti — запомнить.", "Zapamtiti — to remember."),
 ("Majko, nije LGBT *nego* ChatGPT.", ["а","потому что","если","когда"], ["but rather","because","if","when"], 0, "Nije X nego Y — не X, а Y.", "Nije X nego Y — not X but Y."),
],
'G': [
 ("Ajde, ne zanovetaj, bre, nego mi ___.", ["uključi","uključim","uključio","uključiti"], 0, "Повелительное наклонение: uključi — включи.", "Imperative: uključi — turn on."),
 ("Upali ___ onaj LGBT.", ["mi","me","ja","mene"], 0, "Дательный: mi — «мне, для меня».", "Dative: mi — \"for me\"."),
 ("Evo, ___ ti, kaže se ChatGPT, zapamti.", ["palim","pališ","pali","paljenje"], 0, "Первое лицо ед. ч.: palim — включаю.", "First person singular: palim — I turn on."),
 ("A šta ___ ja rekla?", ["sam","je","smo","si"], 0, "Ja → sam: «что я сказала».", "Ja → sam: \"what did I say\"."),
],
}

# Željko — baba i salama
Q['7706903451451641106'] = {
'M': [
 ("Что бабушка хочет приготовить?", "What does grandma want to make?", ["суп","бутерброд","салат","пирог"], ["soup","a sandwich","a salad","a pie"], 1, "Sad će tebe baba da napravi jedan sendvič", "сейчас бабушка сделает тебе бутерброд.", "now grandma will make you a sandwich."),
 ("О чём просит внук?", "What does the grandson ask for?", ["нарезать салями потоньше","добавить сыр","не класть хлеб","подать горячим"], ["to slice the salami thinner","to add cheese","not to use bread","to serve it hot"], 0, "Samo tanje reži salamu", "только режь салями потоньше.", "just slice the salami thinner."),
 ("Почему бабушка не нарезала тоньше?", "Why did grandma not slice it thinner?", ["не было ножа","не смогла","не захотела","забыла"], ["there was no knife","she could not","she did not want to","she forgot"], 1, "Pa sine, ja tanje nisam mogla", "ну сынок, тоньше я не смогла.", "well, son, I could not do it thinner."),
 ("Почему внук не может есть бутерброд?", "Why can the grandson not eat the sandwich?", ["его тошнит от одного вида","он уже сыт","у него аллергия","он не любит хлеб"], ["he feels sick just looking at it","he is already full","he is allergic","he does not like bread"], 0, "Meni je muka samo dok gledam to", "меня тошнит, только когда я на это смотрю.", "I feel sick just looking at it."),
],
'L': [
 ("Samo tanje reži *salamu*.", ["салями","сыр","хлеб","масло"], ["salami","cheese","bread","butter"], 0, "Salama — салями.", "Salama — salami."),
 ("Dobro, sine, *tanko* će baba.", ["тонко","толсто","быстро","вкусно"], ["thinly","thickly","quickly","tastily"], 0, "Tanko — тонко.", "Tanko — thinly."),
 ("Meni je *muka* samo dok gledam to", ["тошно","весело","жарко","страшно"], ["nauseous","fun","hot","scary"], 0, "Muka mi je — меня тошнит.", "Muka mi je — I feel sick."),
 ("Izvolite *sendvič*.", ["бутерброд","суп","чай","торт"], ["sandwich","soup","tea","cake"], 0, "Sendvič — бутерброд, сэндвич.", "Sendvič — a sandwich."),
],
'G': [
 ("Sad će tebe baba da napravi jedan ___.", ["sendvič","sendviča","sendviču","sendvičem"], 0, "Одушевлённость не нужна: вин. п. неодуш. = им. п.", "Inanimate accusative = nominative: sendvič."),
 ("Samo tanje reži ___.", ["salamu","salama","salame","salami"], 0, "Винительный ж. р.: salamu.", "Accusative feminine: salamu."),
 ("Pa sine, ja tanje ___ mogla.", ["nisam","nije","nismo","nisi"], 0, "Ja → nisam: «я не смогла».", "Ja → nisam: \"I could not\"."),
 ("Dobro, baba, je l' ti je to ___ rezano?", ["tanko","tanak","tanka","tanke"], 0, "Наречие: tanko — тонко.", "Adverb: tanko — thinly."),
],
}

# Gagi — test poverenja
Q['7702504712997768468'] = {
'M': [
 ("Сколько месяцев первая пара вместе?", "How many months has the first couple been together?", *N(["1","3","6","12"]), 1, "Tri meseca", "три месяца.", "three months.") if False else ("Сколько месяцев первая пара вместе?", "How many months has the first couple been together?", ["1","3","6","12"], ["1","3","6","12"], 1, "Tri meseca", "три месяца.", "three months."),
 ("В чём состоит тест доверия?", "What is the trust test?", ["поменяться телефонами на минуту","поменяться местами","не говорить минуту","позвонить друзьям"], ["swap phones for a minute","swap seats","stay silent for a minute","call friends"], 0, "treba da zamenite telefone na jedan minut", "нужно поменяться телефонами на одну минуту.", "you have to swap phones for one minute."),
 ("Кто такая Милица в телефоне парня?", "Who is Milica in the boyfriend's phone?", ["его мама","его сестра","его бывшая","его учительница"], ["his mother","his sister","his ex","his teacher"], 0, "To mu je majka, to mu je majka", "это его мама, это его мама.", "that is his mother, that is his mother."),
 ("Что, по словам парня, присылают ему девушки?", "What do the girls send him, according to the boyfriend?", ["домашку","фото","деньги","музыку"], ["homework","photos","money","music"], 0, "Tebi svaka devojka šalje domaći", "тебе каждая девушка присылает домашку.", "every girl sends you homework."),
],
'L': [
 ("Koliko dugo ste u *vezi*?", ["в отношениях","в доме","в пути","в школе"], ["in a relationship","in a house","on the way","at school"], 0, "U vezi — в отношениях.", "U vezi — in a relationship."),
 ("Da li verujete jedno *drugom*?", ["друг другу","никому","себе","им"], ["each other","nobody","yourselves","them"], 0, "Jedno drugom — друг другу.", "Jedno drugom — each other."),
 ("Zašto ga nisi *blokirala*?", ["заблокировала","нашла","позвала","любила"], ["blocked","found","called","loved"], 0, "Blokirati — блокировать.", "Blokirati — to block."),
 ("Ma ništa nisi *našao*, brate.", ["нашёл","взял","видел","сказал"], ["found","took","saw","said"], 0, "Naći — найти.", "Naći — to find."),
],
'G': [
 ("Koliko dugo ste u ___?", ["vezi","veza","vezu","vezom"], 0, "Предложный падеж после u (где?): u vezi.", "Locative after u (where?): u vezi."),
 ("Da li verujete jedno ___?", ["drugom","drugi","drugog","drugim"], 0, "Verovati + дательный: drugom.", "Verovati + dative: drugom."),
 ("Imaš još pet ___.", ["sekundi","sekunda","sekundu","sekundom"], 0, "После пет — родительный мн. ч.: sekundi.", "After pet — genitive plural: sekundi."),
 ("Ne idemo zajedno u istu ___.", ["školu","škola","školi","škole"], 0, "Куда? — винительный: u školu.", "Where to? — accusative: u školu."),
],
}

# Gagi — poruka za bivšeg
Q['7705476511423352085'] = {
'M': [
 ("Какую фразу говорит первая девушка о бывшем?", "What does the first girl say about her ex?", ["Всё хорошее длится недолго","Он лучший","Я его забыла","Он мне снится"], ["Everything nice lasts a short time","He is the best","I forgot him","I dream of him"], 0, "Sve što je lepo kratko traje", "всё хорошее длится недолго.", "everything that is nice lasts a short time."),
 ("Что делает вторая девушка с бывшим?", "What did the second girl do to her ex?", ["заблокировала его","написала ему","позвала на свидание","поблагодарила"], ["blocked him","wrote to him","invited him on a date","thanked him"], 0, "Blokirala sam, nema poruke za njega", "я заблокировала, для него нет сообщения.", "I blocked him, there is no message for him."),
 ("Почему нет сообщения для него?", "Why is there no message for him?", ["он врал","он уехал","он беден","он забыл"], ["he lied","he left","he is poor","he forgot"], 0, "Zato što je lagao", "потому что он врал.", "because he lied."),
 ("Называет ли она его имя?", "Does she say his name?", ["нет, оставит в тайне","да, сразу","только фамилию","показывает фото"], ["no, she keeps it secret","yes, right away","only the surname","she shows a photo"], 0, "Ne treba, brate, ajde, ostaćemo u tajnosti", "не надо, брат, давай, останемся в тайне.", "no need, man, come on, let us keep it secret."),
],
'L': [
 ("*Blokirala* sam, nema poruke za njega.", ["заблокировала","позвала","простила","забыла"], ["blocked","called","forgave","forgot"], 0, "Blokirati — блокировать.", "Blokirati — to block."),
 ("Zato što je *lagao*.", ["врал","шутил","болел","молчал"], ["lied","joked","was ill","was silent"], 0, "Lagati — врать.", "Lagati — to lie."),
 ("Sve što je lepo *kratko* traje.", ["коротко","долго","громко","редко"], ["briefly","long","loudly","rarely"], 0, "Kratko — коротко, недолго.", "Kratko — briefly."),
 ("Hoćeš da kažeš njegovo *ime* da ga prozovemo?", ["имя","лицо","фото","место"], ["name","face","photo","place"], 0, "Ime — имя.", "Ime — name."),
],
'G': [
 ("Poruka za ___ dečka.", ["bivšeg","bivši","bivšem","bivšim"], 0, "За кого? — родительный муж. р.: bivšeg dečka.", "For whom? — genitive masculine: bivšeg dečka."),
 ("Blokirala sam, nema ___ za njega.", ["poruke","poruka","poruku","poruci"], 0, "После nema — родительный: nema poruke.", "After nema — genitive: nema poruke."),
 ("Dosta ___ je lagao, brate.", ["stvari","stvar","stvarima","stvarju"], 0, "После dosta — родительный мн. ч.: stvari.", "After dosta — genitive plural: stvari."),
 ("Ne treba, brate, ajde, ___ u tajnosti.", ["ostaćemo","ostao","ostati","ostanite"], 0, "Будущее время, 1 л. мн. ч.: ostaćemo.", "Future tense, 1st plural: ostaćemo."),
],
}

# Luka — SMS
Q['7703990028006870293'] = {
'M': [
 ("Зачем люди стоят под дождём?", "Why are the people standing in the rain?", ["собирают деньги на лечение","ждут автобус","продают зонты","снимают клип"], ["raising money for treatment","waiting for a bus","selling umbrellas","filming a clip"], 0, "kako bi skupili novac za lečenje njene sestre", "чтобы собрать деньги на лечение её сестры.", "to raise money for her sister's treatment."),
 ("Какая болезнь у Александры?", "What illness does Aleksandra have?", ["рассеянный склероз","грипп","диабет","астма"], ["multiple sclerosis","flu","diabetes","asthma"], 0, "Ima multiplu sklerozu već pet godina", "у неё рассеянный склероз уже пять лет.", "she has had multiple sclerosis for five years."),
 ("Сколько у неё детей?", "How many children does she have?", ["двое","трое","четверо","пятеро"], ["two","three","four","five"], 1, "Ima troje dece", "у неё трое детей.", "she has three children."),
 ("Сколько динаров лежит в подарке?", "How many dinars are in the gift?", ["5.000","15.000","50.000","500.000"], ["5,000","15,000","50,000","500,000"], 2, "Unutra ima 50.000 dinara", "внутри 50 000 динаров.", "there are 50,000 dinars inside."),
],
'L': [
 ("Ovi ljudi stoje po kiši kako bi skupili novac za *lečenje* njene sestre.", ["лечение","обучение","путешествие","свадьба"], ["treatment","education","trip","wedding"], 0, "Lečenje — лечение.", "Lečenje — treatment."),
 ("Ima troje *dece*, najmlađe ima četiri godine.", ["детей","собак","братьев","машин"], ["children","dogs","brothers","cars"], 0, "Deca — дети; troje dece — трое детей.", "Deca — children; troje dece — three children."),
 ("Ali biće potrebno još puno *novca*.", ["денег","времени","людей","еды"], ["money","time","people","food"], 0, "Novac — деньги; род. п. novca.", "Novac — money; gen. novca."),
 ("A mi idemo da ih *iznenadimo* malim poklonom.", ["удивим","спросим","найдём","обидим"], ["surprise","ask","find","offend"], 0, "Iznenaditi — удивить.", "Iznenaditi — to surprise."),
],
'G': [
 ("Ovi ljudi stoje po ___", ["kiši","kiša","kišu","kiše"], 0, "Po + предложный падеж: po kiši — под дождём.", "Po + locative: po kiši — in the rain."),
 ("A mi idemo da ih iznenadimo malim ___", ["poklonom","poklon","poklona","poklone"], 0, "Творительный: чем? — malim poklonom.", "Instrumental: with what? — malim poklonom."),
 ("Ima ___ dece, najmlađe ima četiri godine.", ["troje","tri","trojica","treći"], 0, "Для детей — собирательное число: troje dece.", "For children, the collective numeral: troje dece."),
 ("Hajde zajedno da pomognemo mama Aleksandri da se ___ što pre kući", ["vrati","vratiti","vratila","vraćanje"], 0, "da + настоящее: da se vrati — чтобы вернулась.", "da + present: da se vrati — so that she returns."),
],
}

# Luka — novac na drvetu
Q['7702768555548314901'] = {
'M': [
 ("В чём состоит эксперимент?", "What is the experiment?", ["люди могут взять по одной купюре","люди платят за дерево","люди ищут клад","люди продают деньги"], ["people may take one banknote each","people pay for a tree","people look for treasure","people sell money"], 0, "uzimati samo po jednu novčanicu", "брать только по одной купюре.", "take only one banknote each."),
 ("Как вели себя прохожие сначала?", "How did the passers-by behave at first?", ["были растеряны","убежали","смеялись","ссорились"], ["were confused","ran away","laughed","quarrelled"], 0, "bili malo zbunjeni", "были немного растеряны.", "were a bit confused."),
 ("Чем закончился эксперимент?", "How did the experiment end?", ["все взяли по одной купюре","кто-то взял всё","никто не пришёл","пришла полиция"], ["everyone took one banknote","somebody took all","nobody came","police arrived"], 0, "svi uzeli samo po jednu", "все взяли только по одной.", "everyone took only one."),
],
'L': [
 ("Ko je rekao da *novac* ne raste na drvetu?", ["деньги","цветы","овощи","дети"], ["money","flowers","vegetables","children"], 0, "Novac — деньги.", "Novac — money."),
 ("*Prolaznici* su u početku bili malo zbunjeni", ["прохожие","туристы","дети","соседи"], ["passers-by","tourists","children","neighbours"], 0, "Prolaznik — прохожий.", "Prolaznik — passer-by."),
 ("Čekamo da vidimo da li će svi do kraja biti *pošteni*.", ["честными","богатыми","злыми","усталыми"], ["honest","rich","angry","tired"], 0, "Pošten — честный.", "Pošten — honest."),
],
'G': [
 ("Ko je rekao da novac ne raste na ___", ["drvetu","drvo","drveta","drvetom"], 0, "На чём? — предложный падеж: na drvetu.", "On what? — locative: na drvetu."),
 ("Baš mi je drago da su svi uzeli samo po ___", ["jednu","jedna","jedne","jednom"], 0, "Po + винительный: po jednu (novčanicu).", "Po + accusative: po jednu (banknote)."),
 ("Prolaznici su u početku bili malo ___", ["zbunjeni","zbunjen","zbunjena","zbunjeno"], 0, "Согласуется с мн. ч. м. р.: zbunjeni.", "Agrees with masculine plural: zbunjeni."),
],
}

# BalkanBet — serije
Q['7709123974646517012'] = {
'M': [
 ("Какое название называет девушка для первого отрывка?", "What title does the girl give for the first clip?", ["Bolji život","Selo gori, baba se češlja","Urgentni centar","Naša mala klinika"], ["Bolji život","Selo gori, baba se češlja","Urgentni centar","Naša mala klinika"], 0, "Pa Bolji život", "ну, «Лучшая жизнь».", "well, Bolji život."),
 ("Какое название называет парень для четвёртого отрывка?", "Which title does the guy name for a later clip?", ["Urgentni centar","Bolji život","Lud, zbunjen, normalan","Ranjeni orao"], ["Urgentni centar","Bolji život","Lud, zbunjen, normalan","Ranjeni orao"], 0, "Ovo, brate, Urgentni centar", "это, брат, «Скорая помощь».", "this, man, is Urgentni centar.") if False else ("Какое название называет парень для одного из отрывков?", "Which title does the guy name for one of the clips?", ["Urgentni centar","Bolji život","Dnevnik","Vesti"], ["Urgentni centar","Bolji život","Dnevnik","Vesti"], 0, "Ovo, brate, Urgentni centar", "это, брат, «Скорая помощь».", "this, man, is Urgentni centar."),
 ("Каков итог девушки?", "What is the girl's score?", ["0 из 4","2 из 4","3 из 4","4 из 4"], ["0 of 4","2 of 4","3 of 4","4 of 4"], 0, "nula od četiri", "ноль из четырёх.", "zero out of four."),
 ("Какая серия оказалась ответом на третий отрывок?", "Which series is the answer to the later clip?", ["Selo gori, baba se češlja","Bolji život","Urgentni centar","Naša mala klinika"], ["Selo gori, baba se češlja","Bolji život","Urgentni centar","Naša mala klinika"], 0, "Selo gori, baba se češlja", "«Село горит, а бабушка причёсывается».", "Selo gori, baba se češlja."),
],
'L': [
 ("Za početak, *odakle* je ovo?", ["откуда","куда","когда","почему"], ["from where","where to","when","why"], 0, "Odakle — откуда.", "Odakle — from where."),
 ("Možeš neki *hint*, možda?", ["подсказку","вопрос","шанс","деньги"], ["hint","question","chance","money"], 0, "Hint — подсказка (англ.).", "Hint — English loanword."),
 ("*Ništa*? Ništa, nema veze.", ["ничего","всё","много","никто"], ["nothing","everything","a lot","nobody"], 0, "Ništa — ничего.", "Ništa — nothing."),
 ("Ovo je neka *bolnica*, ne?", ["больница","школа","тюрьма","гостиница"], ["hospital","school","prison","hotel"], 0, "Bolnica — больница.", "Bolnica — hospital."),
],
'G': [
 ("Da. Iz ___ serije?", ["koje","koja","koju","kojoj"], 0, "Iz + родительный: iz koje serije?", "Iz + genitive: iz koje serije?"),
 ("Emitovalo se na ___?", ["Pinku","Pink","Pinka","Pinkom"], 0, "Предложный падеж: na Pinku.", "Locative: na Pinku."),
 ("U ___ serije je posao?", ["imenu","ime","imena","imenom"], 0, "В чём? — предложный падеж: u imenu.", "In what? — locative: u imenu."),
 ("Ovo je neka ___, ne?", ["bolnica","bolnicu","bolnice","bolnici"], 0, "Именительный: neka bolnica.", "Nominative: neka bolnica."),
],
}

# BalkanBet — tablice
Q['7698688609523649813'] = {
'M': [
 ("Что спрашивают у девушек?", "What are the girls asked?", ["чьи в Сербии номера BČ","сколько стоит машина","где ближайшая заправка","как зовут водителя"], ["which plates in Serbia are BČ","how much a car costs","where the nearest petrol station is","what the driver is called"], 0, "koje su u Srbiji tablice BČ", "чьи в Сербии номера BČ.", "which plates in Serbia are BČ."),
 ("Что получит тот, кто угадает?", "What does the one who guesses get?", ["деньги","подарок","машину","телефон"], ["money","a gift","a car","a phone"], 0, "dobijete pare", "получите деньги.", "you get money."),
 ("Какой город предполагает одна из девушек?", "Which town does one of the girls suggest?", ["Параћин","Нови-Сад","Ниш","Крушевац"], ["Paraćin","Novi Sad","Niš","Kruševac"], 0, "Da nije možda Paraćin", "может, это Параћин.", "could it be Paraćin."),
 ("Что парень говорит про Бараћин?", "What does the guy say about Baračin?", ["такого не существует","это его родной город","он там был","он рядом"], ["it does not exist","it is his hometown","he has been there","it is nearby"], 0, "Baračin ne postoji", "Бараћина не существует.", "Baračin does not exist."),
],
'L': [
 ("Jesi čula nekad za te *tablice*?", ["номера","столы","таблицы","планшеты"], ["plates","tables","tablets","charts"], 0, "Tablice — автомобильные номера.", "Tablice — licence plates."),
 ("Ako pogodite — ovo je baš teško — dobijete *pare*.", ["деньги","подарок","приз","шанс"], ["money","gift","prize","chance"], 0, "Pare — деньги.", "Pare — money."),
 ("Mora, moramo da te *nagradimo*.", ["наградим","накажем","спросим","найдём"], ["reward","punish","ask","find"], 0, "Nagraditi — наградить.", "Nagraditi — to reward."),
 ("Ljudi, konačno imamo nekoga ko zna BČ tablice, *svaka čast*.", ["молодец","до свидания","извини","спасибо"], ["well done","goodbye","sorry","thanks"], 0, "Svaka čast — молодец, браво.", "Svaka čast — well done."),
],
'G': [
 ("Devojke, da li znate koje su u ___ tablice BČ?", ["Srbiji","Srbija","Srbiju","Srbije"], 0, "Где? — предложный падеж: u Srbiji.", "Where? — locative: u Srbiji."),
 ("Da nije možda ___?", ["Paraćin","Paraćina","Paraćinu","Paraćinom"], 0, "После da nije — именительный: Paraćin.", "After da nije — nominative: Paraćin."),
 ("Jesi čula nekad za te ___?", ["tablice","tablica","tablicu","tablicama"], 0, "Za + винительный мн. ч.: za te tablice.", "Za + accusative plural: za te tablice."),
 ("Ljudi, konačno imamo ___ ko zna BČ tablice, svaka čast.", ["nekoga","neko","nekome","nekim"], 0, "Imati + винительный: nekoga.", "Imati + accusative: nekoga."),
],
}

# Aveilora — Amerika
Q['7688788596018498823'] = {
'M': [
 ("Куда она едет?", "Where is she going?", ["к своей американской семье","в Белград","на море","в университет"], ["to her American family","to Belgrade","to the seaside","to university"], 0, "idemo kod moje američke porodice", "мы едем к моей американской семье.", "we are going to my American family."),
 ("Сколько часов ехать до Бостона?", "How many hours does it take to get to Boston?", ["около двух","около четырёх","около восьми","около десяти"], ["about two","about four","about eight","about ten"], 1, "do kog nam treba oko četiri sata", "до которого нам около четырёх часов.", "which takes about four hours."),
 ("Какую большую ошибку она сделала?", "What big mistake did she make?", ["переоделась в пижаму","потеряла паспорт","села не на тот автобус","забыла телефон"], ["changed into pyjamas","lost her passport","took the wrong bus","forgot her phone"], 0, "presvukla sam se u pidžamu", "я переоделась в пижаму.", "I changed into pyjamas."),
 ("Что она сделала с чемоданами в час ночи?", "What did she do with her suitcases at one a.m.?", ["положила в тележки для покупок","отдала водителю","оставила в автобусе","взяла с собой в самолёт"], ["put them in shopping carts","gave them to the driver","left them on the bus","took them on the plane"], 0, "sam stavila kofere sa mojim vrednim stvarima u shopping kolica", "я положила чемоданы с моими ценными вещами в тележки для покупок.", "I put the suitcases with my valuable things in shopping carts."),
],
'L': [
 ("Prvi izazov je bio *nagurati* sve ove kofre u auto", ["запихнуть","купить","потерять","открыть"], ["cram","buy","lose","open"], 0, "Nagurati — запихнуть, втиснуть.", "Nagurati — to cram in."),
 ("Osećaj biti ponovo ovde je *nerealan*", ["нереальный","обычный","страшный","тихий"], ["unreal","ordinary","scary","quiet"], 0, "Nerealan — нереальный.", "Nerealan — unreal."),
 ("Od *sramote* sam odmah uzela Uber do aerodroma", ["стыда","радости","скуки","холода"], ["shame","joy","boredom","cold"], 0, "Sramota — стыд.", "Sramota — shame."),
 ("*Let* je trajao malo manje od dva sata", ["полёт","день","путь","дождь"], ["flight","day","road","rain"], 0, "Let — полёт, рейс.", "Let — flight."),
],
'G': [
 ("I danas odlazim iz ___ u kojoj sam živjela celo leto", ["kuće","kuća","kuću","kući"], 0, "Iz + родительный: iz kuće.", "Iz + genitive: iz kuće."),
 ("Krenuli smo za Boston do kog nam treba oko četiri ___", ["sata","sati","sat","satova"], 0, "После 2–4 — родительный ед. ч.: četiri sata.", "After 2–4 — genitive singular: četiri sata."),
 ("i ja sam stigla u Charlotte oko ___ ujutru", ["osam","osmi","osmog","osmoj"], 0, "Oko + числительное: oko osam — около восьми.", "Oko + numeral: oko osam — around eight."),
 ("Zvanično sam opet u svojoj američkoj ___", ["sobi","soba","sobu","sobe"], 0, "Где? — предложный падеж: u svojoj sobi.", "Where? — locative: u svojoj sobi."),
],
}

# Aveilora — pitbull
Q['7707712402485202184'] = {
'M': [
 ("Из чего она делает лысую голову?", "What is she making the bald head out of?", ["из фольги","из бумаги","из ткани","из пластилина"], ["foil","paper","fabric","clay"], 0, "kako od folije da napravim ćelavu glavu", "как из фольги сделать лысую голову.", "how to make a bald head out of foil."),
 ("На чей концерт она собирается?", "Whose concert is she going to?", ["Питбуля","Джей Зи","Марко Лука","Нирван"], ["Pitbull","Jay-Z","Marko Luka","Nirvana"], 0, "ova dama na Pitbulla ne ide ćelava", "эта дама на Питбуля не пойдёт лысой.", "this lady is not going to Pitbull bald."),
 ("Почему ей нужна дешёвая косметика?", "Why does she need cheap make-up?", ["не жалко выдавливать много","она бесплатная","она ярче","она быстрее сохнет"], ["she does not mind squeezing out a lot","it is free","it is brighter","it dries faster"], 0, "mi nije žao da istisnem ovoga koliko god treba", "мне не жалко выдавить этого сколько нужно.", "I do not mind squeezing out as much as needed."),
 ("Чего у неё нет для образа?", "What does she lack for the outfit?", ["белой рубашки и чёрного галстука","костюма","туфель","очков"], ["a white shirt and a black tie","a suit","shoes","glasses"], 0, "nemam ni običnu belu košulju ni običnu crnu kravatu", "у меня нет ни обычной белой рубашки, ни обычного чёрного галстука.", "I do not have an ordinary white shirt or an ordinary black tie."),
],
'L': [
 ("Za početak sam napravila ovu *punđu*, najtanju moguću", ["пучок","косу","хвост","шапку"], ["bun","braid","ponytail","hat"], 0, "Punđa — пучок (причёска).", "Punđa — a hair bun."),
 ("Ok, sada ćemo da *izbušimo* ovde za uvo", ["проделаем дыру","нарисуем","закроем","вытрем"], ["poke a hole","draw","close","wipe"], 0, "Izbušiti — проделать отверстие.", "Izbušiti — to make a hole."),
 ("Ovo možda i bude *funkcionisalo*.", ["сработало","сломалось","упало","исчезло"], ["worked","broke","fell","vanished"], 0, "Funkcionisati — работать, срабатывать.", "Funkcionisati — to work."),
 ("Ja ne mogu da verujem da nemam ni običnu belu *košulju* ni običnu", ["рубашку","куртку","юбку","шляпу"], ["shirt","jacket","skirt","hat"], 0, "Košulja — рубашка.", "Košulja — shirt."),
],
'G': [
 ("Ipak ova dama na ___ ne ide ćelava", ["Pitbulla","Pitbull","Pitbullu","Pitbullom"], 0, "Куда? — винительный: na Pitbulla.", "Where to? — accusative: na Pitbulla."),
 ("jer sam našla tutorijal kako od ___ da napravim ćelavu glavu", ["folije","folija","foliju","folijom"], 0, "Od + родительный: od folije — из фольги.", "Od + genitive: od folije — out of foil."),
 ("Ovo je prvi ___, ne znam kako izgleda od pozadi", ["sloj","sloja","sloju","slojem"], 0, "Именительный: prvi sloj.", "Nominative: prvi sloj."),
 ("Ja ne mogu da verujem da nemam ni običnu belu košulju ni običnu crnu ___", ["kravatu","kravata","kravate","kravati"], 0, "Imati + винительный: kravatu.", "Imati + accusative: kravatu."),
],
}
