import 'store.dart';

class Video {
  const Video({
    required this.id,
    required this.title,
    required this.channel,
    this.topic = '',
    this.level = '',
    this.duration = '',
    this.mine = false,
  });
  final String id, title, channel, topic, level, duration;

  /// Ролик добавил сам пользователь: его нет в каталоге, а субтитры лежат на устройстве.
  final bool mine;
}

/// Креатор из каталога: его канал на YouTube и аватарка оттуда же.
class Creator {
  const Creator(this.handle, this.avatarId);
  final String handle, avatarId;

  String get url => 'https://www.youtube.com/@$handle';
  String get avatar => 'https://yt3.googleusercontent.com/$avatarId=s176-c-k-c0x00ffffff-no-rj';
}

const creators = <String, Creator>{
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

const videos = <Video>[
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
    id: 'D9Fc77qeKdQ',
    title: 'VEŠTAČKA INTELIGENCIJA, Tatjana Gligorić',
    channel: 'SINGIDUNUM VALJEVO',
    topic: 'IT',
    level: 'B2',
    duration: '14:53',
  ),
];

Video? videoById(String id) {
  for (final v in videos) {
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
