import 'store.dart';

class Video {
  const Video({
    required this.id,
    required this.title,
    required this.channel,
    this.topic = '',
    this.level = '',
    this.duration = '',
    this.kind = '',
    this.mine = false,
  });
  final String id, title, channel, topic, level, duration;

  /// Откуда ролик: пусто — YouTube, 'tiktok' — вертикальный клип из TikTok.
  final String kind;

  int get views => _ytViews[id] ?? 0;
  bool get tiktok => kind == 'tiktok';

  /// Заглушка для примерки ленты клипов, см. [kClipMocks]: обложка есть, самого ролика нет.
  bool get mock => id.startsWith('mock-');

  /// Страница клипа в TikTok; имя автора в адресе не обязательно.
  String get tiktokUrl => 'https://www.tiktok.com/@_/video/$id';

  /// Ролик добавил сам пользователь: его нет в каталоге, а субтитры лежат на устройстве.
  final bool mine;

  static Video fromJson(Map<String, dynamic> j) => Video(
    id: j['id'],
    title: j['title'],
    channel: j['channel'],
    topic: j['topic'] ?? '',
    level: j['level'] ?? '',
    duration: j['duration'] ?? '',
    kind: j['kind'] ?? '',
  );
}

/// Просмотры на YouTube на 17.10.2026 — по ним собирается «Популярное». Для новых роликов без записи считаем 0.
const _ytViews = <String, int>{
  'dxE0__WvLBU': 235847,
  '0Kc3ASUSPc0': 22299,
  'XkYKK0qIm-E': 173286,
  'HSh_hA97o7c': 46599,
  'YBwhDmteusg': 24812,
  'wA7VR4Uo0oc': 22655,
  'srODDPxGYkY': 221116,
  'Q6VsddwnvqY': 224150,
  'HONqKSLx680': 1018304,
  'psx84hGjqds': 60581,
  'MZcZFyhKNKw': 111606,
  'cBHmdB67ci4': 194857,
  'APgc8-Vd__c': 6213,
  'Lyg2xhXM9KI': 10438,
  'fUbZYP9j0CY': 604,
  'RLSLcmL-mEY': 902,
  'nAXBTBNoL1s': 115,
  'A4d3e9zh64c': 3690,
  'hBS0MniD5b4': 3687,
  'LPyDl0VGO8M': 1769,
  'NlAc-GePGh8': 47263,
  'j4Dn9F_sIg0': 1366,
  '2Yu3pKxNY5Q': 627,
  '1BNwsNIp31E': 146,
  'XVbTD_qhPL8': 493,
  '4csv5_G5FF0': 172,
  '20D5N4Vjm9I': 412,
  'iKhNlMwn4aw': 123,
  'oz6xKCTAgYU': 155584,
};

/// Креатор из каталога: его канал на YouTube и аватарка оттуда же.
class Creator {
  const Creator(this.handle, this.avatarId);
  final String handle, avatarId;

  String get url => 'https://www.youtube.com/@$handle';
  String get avatar => 'https://yt3.googleusercontent.com/$avatarId=s176-c-k-c0x00ffffff-no-rj';
}

// Каталог живёт в Supabase (таблицы videos и creators). Списки ниже — то, с чем приложение собрано:
// их видно, пока каталог ни разу не загрузился.
Map<String, Creator> creators = _builtInCreators;
List<Video> videos = _builtInVideos;

/// Временно: заглушки в ленте клипов, чтобы посмотреть, как она выглядит заполненной. Перед релизом выключить.
const kClipMocks = true;

/// Клипы из TikTok: у них своя вкладка и вертикальный плеер, в каталоге их нет.
List<Video> clips = [..._builtInClips, if (kClipMocks) ..._mockClips];

/// Подменяет каталог строками из Supabase или их копией с устройства.
void setCatalog(Map<String, dynamic> j) {
  final all = [for (final v in j['videos'] as List) Video.fromJson(v as Map<String, dynamic>)];
  videos = all.where((v) => !v.tiktok).toList();
  // Клипы из сборки остаются, даже если в облаке их ещё нет.
  clips = [
    ...all.where((v) => v.tiktok),
    ..._builtInClips.where((c) => !all.any((v) => v.id == c.id)),
    if (kClipMocks) ..._mockClips,
  ];
  creators = {
    for (final c in (j['creators'] as List).cast<Map<String, dynamic>>())
      if (c['handle'] != null && c['avatar_id'] != null) c['name']: Creator(c['handle'], c['avatar_id']),
  };
}

const _builtInCreators = <String, Creator>{
  'notAleksa': Creator('noaleksa', '5cXh0bO0fYWZZY7M9A-GYlN_xH7OpQF9tmUMFqxuxsPXtJLKdi7JsRLH78_53Fa2YbPQkH4Btw'),
  'Dario Kesegi': Creator(
    'DarioKesegiG0CA',
    'F4iTufu9dOsfJkPp8jUnbiwghDpgAw3qlkowKHyNA6mef34pfXqC7mKdzz-NfX6hkNJnU4kI2g',
  ),
  'vuk1vuk': Creator('vuk1vuk', 'ytc/AIdro_nb3tc3jOWi6Lc2aIi4_HOuPJVSEOxFrnKcSJ--G9f2ZaY'),
  'Potrošački savetnik': Creator('potrosackisavetnik', 'ytc/AIdro_l2-5Y_pwsirmV9Tmy2ldh6oS4ahlk_KXIX-9mttinPCA'),
  'emisija Farma': Creator('emisijafarma', 'ytc/AIdro_mcvvLUDrn7BGid392GKyiuebmx_na6VvS73aw8a3v1krw'),
  'Južne vesti': Creator('juznevesti', 'ytc/AIdro_mf-BKRpXx3RLqm9uQn3l0E3Ba_KnCUN7bSGXJKrXWAwec'),
  'Even M&N': Creator('evenmandn', '07q6K9QKEBYOtrOxGi1Dyf75VukTEvDJMdmjV8TDmA6J_Qn1_0oX-lZEwNcdXRhmqnHFlLqlvw'),
  'Ana Marija & Saša': Creator('anamarijasasa9486', 'ytc/AIdro_kiKflXXGUaqZpvD05mp_1_zcF3s5HPNkdcrnwaGvQyaw'),
  'Tomi tamas': Creator('kulacity', 'ytc/AIdro_nudmK7fH0b6TVfYxDQQynF9fbEagmHJzcW5yA-2sr9qJ8'),
  'What Do You Want / Šta hoćeš': Creator('WdoyouwOrg', 'ytc/AIdro_mdX8JUKCLbtD7DwTZwHq5s-BWVlSHasDmu68_CLxiaxQ'),
  'KCNS': Creator('KCnovisad', 'ytc/AIdro_mvjIgdbC1NmmEpUTnaGDXRzWaP_9wCXpIcjvN-MuQcfg'),
};

const _builtInVideos = <Video>[
  Video(
    id: 'dxE0__WvLBU',
    title: 'Obišao Sam Sela sa Najsmešnijim Imenima u Srbiji',
    channel: 'notAleksa',
    topic: 'Путешествия',
    level: 'B1',
    duration: '10:54',
  ),
  Video(
    id: '0Kc3ASUSPc0',
    title: 'Kidnapovan i bačen u sred Srbije - Geoguessr u pravom životu',
    channel: 'notAleksa',
    topic: 'Путешествия',
    level: 'B1',
    duration: '13:03',
  ),
  Video(
    id: 'XkYKK0qIm-E',
    title: 'Živimo 10 DANA u šatoru! | Kampovanje Ep. 1',
    channel: 'notAleksa',
    topic: 'Путешествия',
    level: 'B1',
    duration: '15:11',
  ),
  Video(
    id: 'HSh_hA97o7c',
    title: '24 SATA KAO ŠPIJUN - Maskiran u DEDU špijuniram prijatelje',
    channel: 'notAleksa',
    topic: 'Эксперименты',
    level: 'B1',
    duration: '14:44',
  ),
  Video(
    id: 'YBwhDmteusg',
    title: 'KAKO ŽIVOTINJE VIDE SVET?',
    channel: 'notAleksa',
    topic: 'Наука',
    level: 'B1',
    duration: '6:52',
  ),
  Video(
    id: 'wA7VR4Uo0oc',
    title: 'Stare kamere su bolje od digitalnih! Čak i za Instagram.',
    channel: 'notAleksa',
    topic: 'Эксперименты',
    level: 'B1',
    duration: '12:00',
  ),
  Video(
    id: 'srODDPxGYkY',
    title: 'Testiram NEUNIŠTIVU kapljicu od stakla! Da li je otporna na METKE?',
    channel: 'notAleksa',
    topic: 'Эксперименты',
    level: 'B1',
    duration: '6:13',
  ),
  Video(
    id: 'Q6VsddwnvqY',
    title: 'SELO protiv GRADA - Trošenje Novca',
    channel: 'Dario Kesegi',
    topic: 'Быт',
    level: 'B2',
    duration: '14:26',
  ),
  Video(
    id: 'HONqKSLx680',
    title: 'Preživeo Sam Zavezan u ŠUMI - Bez Interneta, Bez Mape, Bez Pomoći',
    channel: 'Dario Kesegi',
    topic: 'Путешествия',
    level: 'B2',
    duration: '37:40',
  ),
  Video(
    id: 'psx84hGjqds',
    title: 'Najbolja Mesta za Trening Napolju u Beogradu! Kinez i ja smo ih obišli i ocenili.',
    channel: 'vuk1vuk',
    topic: 'Спорт',
    level: 'B2',
    duration: '35:23',
  ),
  Video(
    id: 'MZcZFyhKNKw',
    title: 'PRIPREMA ZDRAVIH OBROKA ZA CELU NEDELJU',
    channel: 'vuk1vuk',
    topic: 'Еда',
    level: 'B2',
    duration: '21:56',
  ),
  Video(
    id: 'cBHmdB67ci4',
    title: 'Kako kupci FIAT-a 500L mogu ostati i bez para i bez vozila? (2. deo)',
    channel: 'Potrošački savetnik',
    topic: 'Авто',
    level: 'B2',
    duration: '12:08',
  ),
  Video(
    id: 'APgc8-Vd__c',
    title: 'ŽIVOT NA SELU JE LEP!',
    channel: 'emisija Farma',
    topic: 'Быт',
    level: 'B1',
    duration: '8:00',
  ),
  Video(
    id: 'Lyg2xhXM9KI',
    title: 'ETNO SELO IZLAZAK - kompleks za čistu desetku! Plužine',
    channel: 'emisija Farma',
    topic: 'Путешествия',
    level: 'B2',
    duration: '10:37',
  ),
  Video(
    id: 'fUbZYP9j0CY',
    title: 'Film o hiljadama Srba koji se nisu vratili iz norveških logora sniman i u Nišu',
    channel: 'Južne vesti',
    topic: 'История',
    level: 'B2',
    duration: '13:56',
  ),
  Video(
    id: 'RLSLcmL-mEY',
    title: 'Projekat za spas sela',
    channel: 'emisija Farma',
    topic: 'Быт',
    level: 'B2',
    duration: '15:31',
  ),
  Video(
    id: 'nAXBTBNoL1s',
    title: 'Sećanja - Kratki Dokumentarni Film',
    channel: 'Even M&N',
    topic: 'Культура',
    level: 'B2',
    duration: '21:44',
  ),
  Video(
    id: 'A4d3e9zh64c',
    title: 'Deliblatska peščara | Zagajička brda | Odmor u Srbiji',
    channel: 'Ana Marija & Saša',
    topic: 'Путешествия',
    level: 'B1',
    duration: '23:20',
  ),
  Video(
    id: 'hBS0MniD5b4',
    title: '7 ČUDA PRIRODE ISTOČNE SRBIJE ZA 7 DANA | DRUGI DEO',
    channel: 'Ana Marija & Saša',
    topic: 'Путешествия',
    level: 'B1',
    duration: '24:24',
  ),
  Video(
    id: 'LPyDl0VGO8M',
    title: 'Dada - dokumentarni film',
    channel: 'Tomi tamas',
    topic: 'Быт',
    level: 'B2',
    duration: '26:22',
  ),
  Video(
    id: 'NlAc-GePGh8',
    title: 'Odliv mozgova: Dejan Tiago Stanković (1965-2022)',
    channel: 'What Do You Want / Šta hoćeš',
    topic: 'Культура',
    level: 'B2',
    duration: '28:51',
  ),
  Video(
    id: 'j4Dn9F_sIg0',
    title: 'Dokumentarni film "Bluz garavih sokaka"',
    channel: 'KCNS',
    topic: 'Культура',
    level: 'B2',
    duration: '36:30',
  ),
  Video(
    id: '2Yu3pKxNY5Q',
    title: 'Šta je startap?',
    channel: 'StudentFounders',
    topic: 'IT',
    level: 'B1',
    duration: '5:26',
  ),
  Video(
    id: '1BNwsNIp31E',
    title: 'Kako saznati ko je Vaš idealan kupac | Mapa Empatije',
    channel: 'StudentFounders',
    topic: 'Дизайн',
    level: 'B1',
    duration: '10:33',
  ),
  Video(
    id: 'XVbTD_qhPL8',
    title: 'Slavimir Stojanović - Za Beograd (Aleksandra Simić)',
    channel: 'Nasa Televizija',
    topic: 'Дизайн',
    level: 'B2',
    duration: '12:28',
  ),
  Video(
    id: '4csv5_G5FF0',
    title: 'Hipkon Lajt 2020 | Novi (normalni) rad - Tamara Kojić',
    channel: 'Heapspace',
    topic: 'IT',
    level: 'B2',
    duration: '30:14',
  ),
  Video(
    id: '20D5N4Vjm9I',
    title: 'MAKEUP ZA SVAKI DAN 🫵',
    channel: 'Andjela Markovic',
    topic: 'Красота',
    level: 'B1',
    duration: '10:39',
  ),
  Video(
    id: 'iKhNlMwn4aw',
    title: 'Hipkon Lajt 2020 | Design thinking - Kako da stvarate proizvode koje ljudi žele - Milovan Dekić',
    channel: 'Heapspace',
    topic: 'Дизайн',
    level: 'B2',
    duration: '32:20',
  ),
  Video(
    id: 'oz6xKCTAgYU',
    title: 'Kako postati HAKER',
    channel: 'Štreberi',
    topic: 'IT',
    level: 'B1',
    duration: '7:27',
  ),
];

const _builtInClips = <Video>[
  Video(
    id: '7663466480683519265',
    title: 'Najgora pljačka u karijeri',
    channel: 'Realno',
    topic: 'Юмор',
    level: 'B1',
    duration: '1:04',
    kind: 'tiktok',
  ),
  Video(
    id: '7684326403902360852',
    title: 'Koliko smo sada lepše',
    channel: 'Elena',
    topic: 'Красота',
    level: 'B1',
    duration: '2:12',
    kind: 'tiktok',
  ),
  Video(
    id: '7691370106257034504',
    title: 'Prvi alpaka kafe u Srbiji',
    channel: 'milli',
    topic: 'Путешествия',
    level: 'B1',
    duration: '0:45',
    kind: 'tiktok',
  ),
  Video(
    id: '7695697222444387604',
    title: 'Zgrada koja izgleda kao Toblerone',
    channel: 'Ljudi Beograda',
    topic: 'Город',
    level: 'B1',
    duration: '0:44',
    kind: 'tiktok',
  ),
  Video(
    id: '7691647020758502662',
    title: 'Sto godina pijace Zeleni venac',
    channel: 'Ljudi Beograda',
    topic: 'Город',
    level: 'B1',
    duration: '0:50',
    kind: 'tiktok',
  ),
  Video(
    id: '7691254334730226964',
    title: 'Topolska 18: adresa dve kultne serije',
    channel: 'Ljudi Beograda',
    topic: 'Культура',
    level: 'B1',
    duration: '1:02',
    kind: 'tiktok',
  ),
  Video(
    id: '7636300414652026120',
    title: 'Ledene kocke',
    channel: 'Nespretna domaćica',
    topic: 'Еда',
    level: 'B1',
    duration: '0:38',
    kind: 'tiktok',
  ),
  Video(
    id: '7685347257029348626',
    title: 'Najmekša proja',
    channel: 'Lelina kuhinjica',
    topic: 'Еда',
    level: 'B1',
    duration: '0:30',
    kind: 'tiktok',
  ),
  Video(
    id: '7640223671985900818',
    title: 'Domaće ćufte u paradajz sosu',
    channel: 'Poklopac i lonac',
    topic: 'Еда',
    level: 'B1',
    duration: '0:33',
    kind: 'tiktok',
  ),
  Video(
    id: '7694709604017507591',
    title: 'Teorija nevidljive žice',
    channel: 'Đole · Pametni kutak',
    topic: 'Психология',
    level: 'B1',
    duration: '0:46',
    kind: 'tiktok',
  ),
  Video(
    id: '7495076935429672247',
    title: 'Savršeni jednodnevni izlet u Srbiji',
    channel: 'Tragom horizonta',
    topic: 'Путешествия',
    level: 'B1',
    duration: '0:40',
    kind: 'tiktok',
  ),
  Video(
    id: '7627473268941016341',
    title: 'Tortilja pita iz rerne',
    channel: 'Ema Pumpalović',
    topic: 'Еда',
    level: 'B1',
    duration: '0:34',
    kind: 'tiktok',
  ),
  Video(
    id: '7485479524428156166',
    title: 'Život u studentskom domu',
    channel: 'Aleksandra Tepavac',
    topic: 'Быт',
    level: 'B1',
    duration: '0:38',
    kind: 'tiktok',
  ),
];

// Обложки заглушек — кадры роликов из каталога: в id после «mock-» стоит id ролика на YouTube.
const _mockClips = <Video>[
  Video(
    id: 'mock-Q6VsddwnvqY',
    title: 'Kad odeš na selo kod bake',
    topic: 'Юмор',
    channel: 'Realno',
    duration: '0:48',
    kind: 'tiktok',
  ),
  Video(
    id: 'mock-MZcZFyhKNKw',
    title: 'Šta jedem u jednom danu',
    topic: 'Еда',
    channel: 'Mila kuva',
    duration: '0:35',
    kind: 'tiktok',
  ),
  Video(
    id: 'mock-0Kc3ASUSPc0',
    title: 'Pitao sam prolaznike gde je centar',
    topic: 'Юмор',
    channel: 'Ulična anketa',
    duration: '1:12',
    kind: 'tiktok',
  ),
  Video(
    id: 'mock-HSh_hA97o7c',
    title: 'Tipovi komšija u zgradi',
    channel: 'Realno',
    topic: 'Юмор',
    duration: '0:52',
    kind: 'tiktok',
  ),
  Video(
    id: 'mock-XkYKK0qIm-E',
    title: 'Kampovanje: očekivanja i stvarnost',
    topic: 'Путешествия',
    channel: 'Napolju',
    duration: '0:41',
    kind: 'tiktok',
  ),
  Video(
    id: 'mock-YBwhDmteusg',
    title: 'Tri reči koje stranci uvek pogreše',
    topic: 'Язык',
    channel: 'Srpski za minut',
    duration: '0:58',
    kind: 'tiktok',
  ),
  Video(
    id: 'mock-psx84hGjqds',
    title: 'Trening u parku za 5 minuta',
    topic: 'Спорт',
    channel: 'Vežbaj sa mnom',
    duration: '1:05',
    kind: 'tiktok',
  ),
];

Video? videoById(String id) {
  for (final v in videos.followedBy(clips)) {
    if (v.id == id) return v;
  }
  return store.myVideo(id)?.video;
}

final _idInUrl = RegExp(r'(?:v=|youtu\.be/|embed/|shorts/|live/)([\w-]{11})');
final _bareId = RegExp(r'^[\w-]{11}$');

/// Достаёт id ролика из ссылки YouTube или из самого id.
String? parseVideoId(String s) {
  s = s.trim();
  return _idInUrl.firstMatch(s)?[1] ?? (_bareId.hasMatch(s) ? s : null);
}
