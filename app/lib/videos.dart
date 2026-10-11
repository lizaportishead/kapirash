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
