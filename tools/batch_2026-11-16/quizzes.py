import random
Q = {}
Q['Haw-E4vxBYg'] = {
'M': [
 ("Почему Милентие не хочет ехать в Будапешт на машине?", "Why doesn't Milentije want to go to Budapest by car?",
  ["Машина старая и может сломаться", "Нет денег на бензин", "У него нет прав", "Машина в ремонте"], ["The car is old and may break down", "No money for petrol", "He has no licence", "The car is being repaired"], 0,
  "Ako crkne, nema ko da ga gura.", "если заглохнет, толкать её некому.", "if it dies, there's nobody to push it."),
 ("Что Роза сначала думает о билетах, которые ищет сын?", "What does Roza first assume about the tickets her son is looking for?",
  ["Что это входные билеты на Калемегдан", "Что это билеты в кино", "Что это билеты на футбол", "Что это билеты на поезд"], ["That they are admission tickets to Kalemegdan", "That they are cinema tickets", "That they are football tickets", "That they are train tickets"], 0,
  "Bože, pa nisam znala da naplaćuju ulaznice na Kalemegdanu.", "Боже, я не знала, что на Калемегдане продают входные билеты.", "God, I didn't know they charge admission at Kalemegdan."),
 ("Что оказывается на самом деле за билеты?", "What do the tickets turn out to be?",
  ["Билеты в Будапешт", "Билеты в Вену", "Билеты на концерт", "Билеты в цирк"], ["Tickets to Budapest", "Tickets to Vienna", "Concert tickets", "Circus tickets"], 0,
  "Ali ovo su karte za Budimpeštu.", "но это билеты в Будапешт.", "But these are tickets for Budapest."),
 ("Зачем Милентие соврал маме и Мише?", "Why did Milentije lie to Mum and Miša?",
  ["Чтобы Миша пришёл присматривать за мамой, а он смог уехать", "Чтобы получить деньги", "Чтобы мама пошла к врачу", "Чтобы Миша женился"], ["So that Miša would come to look after Mum and he could get away", "To get money", "So that Mum would see a doctor", "So that Miša would marry"], 0,
  "Slagao sam tebe, slagao sam Mišu da bi on došao da te čuva, ali jedino tako ja mogu da odem na par dana.", "я соврал тебе, соврал Мише, чтобы он пришёл за тобой присматривать, но только так я могу уехать на пару дней.", "I lied to you, I lied to Miša so he'd come to look after you, but that's the only way I can get away for a couple of days."),
 ("Что делает Роза, когда сын требует билеты?", "What does Roza do when her son demands the tickets?",
  ["Устраивает ему сеанс психоанализа", "Вызывает полицию", "Прячется в шкафу", "Отдаёт билеты сразу"], ["Gives him a psychoanalysis session", "Calls the police", "Hides in the wardrobe", "Hands over the tickets at once"], 0,
  "Janoš, izvini, molim te, ovo će sada biti psihoanalitička seansa, a tebe ću posle zvati Frojd.", "Янош, извини, пожалуйста, сейчас будет психоаналитический сеанс, а тебя я потом буду звать Фрейд.", "Janoš, sorry, please, this will now be a psychoanalytic session, and I'll call you Freud afterwards."),
 ("Что записывает интервьюер в анкете в ответ на «Врнячка баня, Партизанске воде, Будва»?", "What does the interviewer write down after «Vrnjačka Banja, Partizanske Vode, Budva»?",
  ["Азия", "Европа", "Африка", "Америка"], ["Asia", "Europe", "Africa", "America"], 0,
  "Ako vam je svejedno, zapisaću Azija.", "если вам всё равно, запишу «Азия».", "if it's all the same to you, I'll write down Asia."),
 ("Что предлагает Миша брату?", "What does Miša offer his brother?",
  ["Остаться с мамой, а к девушке он «подскочит» сам", "Одолжить денег", "Отвезти их в Будапешт", "Позвонить Секе"], ["To stay with Mum while he himself «steps in» for the girl", "To lend money", "To drive them to Budapest", "To call Seka"], 0,
  "Ti se nađi mami ovde, a devojci ću ja da priskočim.", "ты займись здесь мамой, а к девушке я сам подскочу.", "You take care of Mum here, and I'll step in for the girl."),
 ("Где, по словам Йованки, Миша на самом деле?", "Where, according to Jovanka, is Miša supposed to be?",
  ["На конференции во Врнячке-Бане", "В Будапеште", "В больнице", "У друзей в Нови-Саде"], ["At a conference in Vrnjačka Banja", "In Budapest", "In the hospital", "With friends in Novi Sad"], 0,
  "Kaže Jovanka da je otputovao na neko savetovanje u Vrnjačku banju.", "Йованка говорит, что он уехал на какую-то конференцию во Врнячку баню.", "Jovanka says he went to some conference in Vrnjačka Banja."),
],
'L': [
 ("Ja bih mogao *udžbenik* da napišem.", ["учебник", "роман", "письмо", "словарь"], ["textbook", "novel", "letter", "dictionary"], 0, "udžbenik — учебник.", "udžbenik — textbook."),
 ("Ima Wi-Fi, ima *klimu*, ima televizor, ima WC.", ["кондиционер", "кухню", "кровать", "балкон"], ["air conditioning", "kitchen", "bed", "balcony"], 0, "klima — кондиционер.", "klima — air conditioning."),
 ("Nekako si postao isuviše *posesivan*, znaš.", ["собственнический", "ленивый", "весёлый", "усталый"], ["possessive", "lazy", "cheerful", "tired"], 0, "posesivan — собственнический.", "posesivan — possessive."),
 ("Kaže da su karte u *džepu*.", ["кармане", "сумке", "ящике", "шкафу"], ["pocket", "bag", "drawer", "wardrobe"], 0, "džep — карман; džepu — местный падеж.", "džep — pocket; džepu is the locative."),
 ("Biću *odsutan* samo tri dana.", ["отсутствовать", "болен", "занят", "свободен"], ["absent", "ill", "busy", "free"], 0, "odsutan — отсутствующий.", "odsutan — absent."),
 ("Nemoj, šta će da kaže komšija Mađarević ako mu *ubiješ* mačku.", ["убьёшь", "найдёшь", "купишь", "накормишь"], ["you kill", "you find", "you buy", "you feed"], 0, "ubiti — убить; ubiješ — 2 л. ед. ч.", "ubiti — to kill; ubiješ is 2nd sg."),
 ("Ima da te lepo *isečem* na komade i da te prodam kineskom restoranu!", ["нарежу", "помою", "напишу", "научу"], ["I'll chop", "I'll wash", "I'll write", "I'll teach"], 0, "iseći — нарезать; isečem — 1 л. ед. ч.", "iseći — to cut up; isečem is 1st sg."),
 ("Mnogo je *teško* sa starima.", ["тяжело", "весело", "дёшево", "быстро"], ["hard", "fun", "cheap", "fast"], 0, "teško — тяжело.", "teško — hard, difficult."),
],
'G': [
 ("Šta ćeš ti tri dana na ___?", ["Kalemegdanu", "Kalemegdan", "Kalemegdana", "Kalemegdanom"], 0, "Предлог «na» с местом — местный падеж: na Kalemegdanu.", "«Na» for a place takes the locative: na Kalemegdanu."),
 ("Pitaš jednog od njih ___ i eto.", ["dvojice", "dvojica", "dvojici", "dvojicu"], 0, "После «od» — родительный падеж: od njih dvojice.", "After «od» comes the genitive: od njih dvojice."),
 ("Sa ___, čeka me dole u autu", ["Sekom", "Seka", "Seku", "Seke"], 0, "Предлог «sa» требует творительного падежа: sa Sekom.", "«Sa» takes the instrumental: sa Sekom."),
 ("Pošto je Azija, zapisaću ___.", ["avionom", "avion", "aviona", "avionu"], 0, "Средство передвижения — творительный падеж: avionom.", "Means of transport takes the instrumental: avionom."),
 ("Kojim prevoznim ___ najviše volite da putujete?", ["sredstvom", "sredstvo", "sredstva", "sredstvu"], 0, "Kojim ... sredstvom — творительный падеж ср. р.", "Kojim ... sredstvom — neuter instrumental."),
 ("Pa zašto me nisi upoznao sa ___?", ["prijateljicom", "prijateljica", "prijateljicu", "prijateljice"], 0, "Upoznati (nekoga) sa + творительный: sa prijateljicom.", "Upoznati sa + instrumental: sa prijateljicom."),
 ("Ja sam tu da ti ___.", ["pomognem", "pomogneš", "pomoći", "pomogao"], 0, "После «da» — настоящее время, 1 л. ед. ч.: da ti pomognem.", "After «da» the present tense, 1st sg.: da ti pomognem."),
 ("Pa dve ___, tri dana.", ["noći", "noć", "noćima", "noćom"], 0, "После «dve» — родительный падеж ед. ч.: dve noći.", "After «dve» the genitive singular: dve noći."),
],
}
Q['f1qsclLQyzQ'] = {
'M': [
 ("Что предлагает Роза сыну в субботу вечером?", "What does Roza offer her son on Saturday night?",
  ["Выйти с ним куда-нибудь", "Сыграть в карты", "Посмотреть сериал", "Позвать Нину"], ["To go out somewhere with him", "To play cards", "To watch a series", "To call Nina"], 0,
  "E, hoćeš možda da ja izađem s tobom?", "ну а хочешь, я выйду с тобой?", "well, do you want me to go out with you?"),
 ("Почему Милентие не может выйти один?", "Why can't Milentije go out alone?",
  ["Через полчаса ему приходится возвращаться к маме и её лекарствам", "У него нет денег", "Он боится темноты", "Ему запретила Нина"], ["After half an hour he has to come back to Mum and her medicines", "He has no money", "He's afraid of the dark", "Nina forbade him"], 0,
  "posle pola sata da se vraćam kući", "через полчаса возвращаться домой", "come back home after half an hour"),
 ("Что Роза зачитывает вслух?", "What does Roza read aloud?",
  ["Объявления о знакомстве", "Рецепт пирога", "Новости", "Письмо от Нины"], ["Dating ads", "A pie recipe", "The news", "A letter from Nina"], 0,
  "Zovem se Dragoljubka", "меня зовут Драголюбка", "my name is Dragoljubka"),
 ("Как Роза говорит о Нине, когда та приходит?", "How does Roza speak about Nina when she arrives?",
  ["Говорит, что обожает её", "Говорит, что ненавидит её", "Не узнаёт её", "Говорит, что она ей чужая"], ["She says she adores her", "She says she hates her", "She doesn't recognise her", "She says she's a stranger"], 0,
  "A pa obožavam Ninu.", "а я обожаю Нину.", "oh, I adore Nina."),
 ("Что Роза раньше говорила о Нине?", "What did Roza use to say about Nina?",
  ["Что она никогда не была в опере", "Что она слишком много тратит", "Что она старше Милентие", "Что она не умеет водить"], ["That she'd never been to the opera", "That she spends too much", "That she's older than Milentije", "That she can't drive"], 0,
  "da ima čukljeve i da nikad u životu nije bila u operi", "что у неё косточки на ногах и она ни разу в жизни не была в опере", "that she has bunions and has never been to the opera in her life"),
 ("Сколько лет молодому человеку Нины?", "How old is Nina's young man?",
  ["Восемнадцать", "Двадцать четыре", "Тридцать", "Сорок"], ["Eighteen", "Twenty-four", "Thirty", "Forty"], 0,
  "Osamnaest!", "Восемнадцать!", "Eighteen!"),
 ("Почему в доме нет чая?", "Why is there no tea in the house?",
  ["Роза выжгла кастрюльку", "Роза всё выпила", "Милентие его выбросил", "Чай не купили"], ["Roza burned the little pot", "Roza drank it all", "Milentije threw it away", "Nobody bought it"], 0,
  "Ali je izgorelo lonče.", "но кастрюлька сгорела.", "but the little pot burned."),
 ("Как зовут няню, которую прислала Йованка?", "What is the name of the babysitter Jovanka sends?",
  ["Боса", "Роза", "Нина", "Сека"], ["Bosa", "Roza", "Nina", "Seka"], 0,
  "Ja sam Bosa.", "а я Боса.", "I'm Bosa."),
],
'L': [
 ("Mnogi ljudi nemaju s kim da izađu *subotom* uveče.", ["по субботам", "по утрам", "в воскресенье", "в пятницу"], ["on Saturdays", "in the mornings", "on Sunday", "on Friday"], 0, "subotom — по субботам, в субботу.", "subotom — on Saturdays."),
 ("Ili na *korzo* da prošetamo, opusti se.", ["корзо, променад", "рынок", "кладбище", "стадион"], ["the promenade", "the market", "the cemetery", "the stadium"], 0, "korzo — променад, где гуляют вечером.", "korzo — the evening promenade."),
 ("Pa možemo i u *diskoteku*.", ["дискотеку", "библиотеку", "аптеку", "баню"], ["disco", "library", "pharmacy", "bathhouse"], 0, "diskoteka — дискотека.", "diskoteka — disco."),
 ("Starateljstvo.", ["опека", "наследство", "развод", "залог"], ["guardianship", "inheritance", "divorce", "deposit"], 0, "starateljstvo — опека.", "starateljstvo — guardianship."),
 ("Ovo ima *pesnički* talenat, da.", ["поэтический", "музыкальный", "актёрский", "математический"], ["poetic", "musical", "acting", "mathematical"], 0, "pesnički — поэтический.", "pesnički — poetic."),
 ("Nisam *gladna*.", ["голодная", "усталая", "больная", "злая"], ["hungry", "tired", "ill", "angry"], 0, "gladan — голодный.", "gladan — hungry."),
 ("U ovoj kući samo ja imam pravo da baratam *oštrim* predmetima.", ["острыми", "тяжёлыми", "старыми", "чужими"], ["sharp", "heavy", "old", "other people's"], 0, "oštar — острый.", "oštar — sharp."),
 ("Pa to ti je *nesanica*.", ["бессонница", "простуда", "усталость", "мигрень"], ["insomnia", "a cold", "tiredness", "a migraine"], 0, "nesanica — бессонница.", "nesanica — insomnia."),
],
'G': [
 ("Hoćeš da ti čitam ___?", ["novine", "novina", "novinama", "novinom"], 0, "Čitati + винительный падеж: novine (мн. ч.).", "Čitati + accusative: novine (plural)."),
 ("Imam to što je ostavila ___ sina.", ["mog", "moj", "moja", "mojem"], 0, "Одушевлённый муж. р. в винительном падеже: mog sina.", "Animate masculine accusative: mog sina."),
 ("Idem ja da skuvam čaj, a vi me čekajte u ___.", ["sobi", "soba", "sobu", "sobe"], 0, "«U» с местом — местный падеж: u sobi.", "«U» for a place takes the locative: u sobi."),
 ("Ne znam da li je taj čaj dobar na ___ stomak.", ["prazan", "prazno", "prazna", "praznog"], 0, "Неодушевлённое муж. р. в винительном падеже: prazan stomak.", "Inanimate masculine accusative: prazan stomak."),
 ("Ja ću ti doneti iz ___ kolač.", ["restorana", "restoran", "restoranu", "restoranom"], 0, "Предлог «iz» требует родительного падежа: iz restorana.", "The preposition «iz» takes the genitive: iz restorana."),
 ("Zato privedite taj razvod ___.", ["kraju", "kraj", "kraja", "krajem"], 0, "Privesti kraju — довести до конца (дательный падеж).", "Privesti kraju — to bring to an end (dative)."),
 ("Ne umem da ___.", ["štrikam", "štrikaš", "štrika", "štrikaju"], 0, "После «da» — настоящее время; 1 л. ед. ч.: štrikam.", "After «da» the present tense; 1st sg.: štrikam."),
 ("Dobro veče, ___.", ["Roso", "Rosa", "Rosu", "Rosom"], 0, "Звательный падеж от Rosa — Roso.", "The vocative of Rosa is Roso."),
],
}
Q['vE6iiAVoD3c'] = {
'M': [
 ("Что Милентие купил маме на день рождения?", "What did Milentije buy Mum for her birthday?",
  ["Бурек", "Торт", "Цветы", "Духи"], ["Burek", "A cake", "Flowers", "Perfume"], 0,
  "Burek. Šta da ti kupim u pet ujutru, samo je pekara otvorena.", "бурек. Что я тебе куплю в пять утра, открыта только пекарня.", "burek. What should I buy you at five in the morning, only the bakery is open."),
 ("Что написано на открытке к цветам?", "What is written on the card with the flowers?",
  ["Самому красивому цветку из райского сада", "С днём рождения, Роза", "Не забывай меня", "Жду тебя вечером"], ["To the most beautiful flower from the garden of paradise", "Happy birthday, Roza", "Don't forget me", "I'll be waiting for you tonight"], 0,
  "Kaže: najlepšem cvetu iz rajske bašte.", "там сказано: самому прекрасному цветку из райского сада.", "it says: to the most beautiful flower from the garden of paradise."),
 ("Что Роза говорит о мужских именах?", "What does Roza say about men's names?",
  ["У неё всегда были с ними проблемы", "Она их все помнит", "Ей нравится имя Лазарь", "Она любит давать прозвища"], ["She has always had trouble with them", "She remembers them all", "She likes the name Lazar", "She likes to give nicknames"], 0,
  "Pa, znaš da sam uvek imala problem sa muškim imenima.", "ну, ты же знаешь, что у меня всегда были проблемы с мужскими именами.", "well, you know I've always had trouble with men's names."),
 ("Кого Роза позвала на ужин?", "Whom did Roza invite to dinner?",
  ["Своего нового знакомого", "Соседку", "Свою сестру", "Врача Мишу"], ["Her new man friend", "A neighbour", "Her sister", "Doctor Miša"], 0,
  "Večeras, brate, zvala sam ga na večeru.", "сегодня вечером, брат, я позвала его на ужин.", "tonight, man, I invited him to dinner."),
 ("Какой «секрет» Роза добавляет в яблочный пирог?", "What «secret» does Roza add to her apple pie?",
  ["Орегано", "Перец", "Мёд", "Имбирь"], ["Oregano", "Pepper", "Honey", "Ginger"], 0,
  "Ja lepo stavim vanilin šećer, doduše to stavim na kraju, i stavim malo origana.", "я красиво кладу ванильный сахар, правда, в конце, и кладу немного орегано.", "I nicely add vanilla sugar, although at the end, and I add a little oregano."),
 ("Что Милентие находит в духовке?", "What does Milentije find in the oven?",
  ["Теннисный мячик", "Ботинок", "Ключи", "Кошку"], ["A tennis ball", "A shoe", "Keys", "A cat"], 0,
  "Jao, Roso, otkud teniska loptica u rerni?", "ох, Роза, откуда в духовке теннисный мячик?", "oh, Roza, where does a tennis ball in the oven come from?"),
 ("Какую новость слышат Йованка и Миша?", "What news do Jovanka and Miša hear?",
  ["У мамы есть парень", "Мама переезжает", "Мама продаёт квартиру", "Милентие женится"], ["Mum has a boyfriend", "Mum is moving out", "Mum is selling the flat", "Milentije is getting married"], 0,
  "Mama ima dečka.", "у мамы есть парень.", "Mum has a boyfriend."),
 ("Как на самом деле зовут «Лазаря»?", "What is «Lazar»'s real name?",
  ["Славко", "Милан", "Милош", "Миленко"], ["Slavko", "Milan", "Miloš", "Milenko"], 0,
  "Hvala, pravo ime mi je Slavko, ali pošto me Rosa zove Lazar, neka ostane tako.", "спасибо, моё настоящее имя Славко, но раз Роза зовёт меня Лазарем, пусть так и остаётся.", "thanks, my real name is Slavko, but since Rosa calls me Lazar, let it stay that way."),
],
'L': [
 ("Sram te bilo, *zlotvore* jedan.", ["злодей", "глупец", "лентяй", "друг"], ["villain", "fool", "slacker", "friend"], 0, "zlotvor — злодей.", "zlotvor — villain."),
 ("Ljubomora je pretirani strah od *gubitka*.", ["потери", "смерти", "ошибки", "болезни"], ["loss", "death", "mistake", "illness"], 0, "gubitak — потеря; gubitka — род. п.", "gubitak — loss; gubitka is the genitive."),
 ("Pa se još pitam šta će ti *biber* u piti od jabuka.", ["перец", "соль", "сахар", "мёд"], ["pepper", "salt", "sugar", "honey"], 0, "biber — перец.", "biber — pepper."),
 ("Daj mi *cimet*.", ["корицу", "ложку", "нож", "миску"], ["cinnamon", "a spoon", "a knife", "a bowl"], 0, "cimet — корица.", "cimet — cinnamon."),
 ("Kako se kaže mera za *dragocenost*?", ["драгоценность", "скорость", "длину", "погоду"], ["preciousness", "speed", "length", "weather"], 0, "dragocenost — драгоценность.", "dragocenost — preciousness."),
 ("Svaka *kuvarica* ima svoj recept.", ["повариха", "соседка", "учительница", "врач"], ["cook (f.)", "neighbour (f.)", "teacher (f.)", "doctor"], 0, "kuvarica — повариха.", "kuvarica — a female cook."),
 ("A kad se mama *uda*, šta ćeš ti da radiš?", ["выйдет замуж", "заболеет", "уедет", "проснётся"], ["gets married", "falls ill", "leaves", "wakes up"], 0, "udati se — выйти замуж.", "udati se — (of a woman) to get married."),
 ("Mogu da vam čuvam decu, pa da spavamo kao *braća*.", ["братья", "друзья", "соседи", "гости"], ["brothers", "friends", "neighbours", "guests"], 0, "braća — братья.", "braća — brothers."),
],
'G': [
 ("Ti si čovek sa mnogo dobrih ___.", ["osobina", "osobine", "osobinama", "osobinu"], 0, "После «mnogo» — родительный падеж мн. ч.: osobina.", "After «mnogo» the genitive plural: osobina."),
 ("Pa moram i ja s nekim da se ___.", ["družim", "družiš", "družimo", "družio"], 0, "После «da» — настоящее время; 1 л. ед. ч.: družim se.", "After «da» the present tense; 1st sg.: družim se."),
 ("Kome ćeš ti da ___?", ["pripadneš", "pripadnem", "pripadnemo", "pripala"], 0, "После «da» — 2 л. ед. ч.: pripadneš.", "After «da» the 2nd sg.: pripadneš."),
 ("Mogla si nešto ___ da obučeš.", ["drugo", "drugi", "druga", "drugog"], 0, "После «nešto» — прилагательное ср. р.: nešto drugo.", "After «nešto» the neuter adjective: nešto drugo."),
 ("Poslednji put je bio u ___ 1984. godine.", ["pozorištu", "pozorište", "pozorišta", "pozorištem"], 0, "«U» с местом — местный падеж: u pozorištu.", "«U» for a place takes the locative: u pozorištu."),
 ("Ja sam mislio kod ___.", ["vas", "vama", "vi", "vaš"], 0, "Предлог «kod» требует родительного падежа: kod vas.", "The preposition «kod» takes the genitive: kod vas."),
 ("Ljudi, idem da vidim šta je sa ___.", ["pitom", "pita", "pitu", "pite"], 0, "Предлог «sa» требует творительного падежа: sa pitom.", "«Sa» takes the instrumental: sa pitom."),
 ("Ne, ne možeš, zamrznućeš se na ___.", ["terasi", "terasa", "terasu", "terase"], 0, "«Na» с местом — местный падеж: na terasi.", "«Na» for a place takes the locative: na terasi."),
],
}
# shuffle options (deterministic) so the right answer isn't always first
rng = random.Random(1116)
for vid, d in Q.items():
    for k in ('M', 'L', 'G'):
        out = []
        for x in d[k]:
            x = list(x)
            if k == 'M': io, eo, ai = 2, 3, 4
            elif k == 'L': io, eo, ai = 1, 2, 3
            else: io, eo, ai = 1, None, 2
            perm = list(range(4)); rng.shuffle(perm)
            x[io] = [x[io][p] for p in perm]
            if eo is not None: x[eo] = [x[eo][p] for p in perm]
            x[ai] = perm.index(x[ai])
            out.append(tuple(x))
        d[k] = out
