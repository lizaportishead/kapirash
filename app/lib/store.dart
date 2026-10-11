import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subs.dart';
import 'subs_generator.dart';
import 'videos.dart';

class SavedWord {
  SavedWord({required this.key, required this.tr, required this.ctx, required this.t, required this.video});
  final String key, tr, ctx, video;
  final double t;

  Map<String, dynamic> toJson() => {'key': key, 'tr': tr, 'ctx': ctx, 't': t, 'video': video};
  static SavedWord fromJson(Map<String, dynamic> j) => SavedWord(
    key: j['key'],
    tr: j['tr'] ?? '',
    ctx: j['ctx'] ?? '',
    t: (j['t'] as num).toDouble(),
    video: j['video'] ?? '',
  );
}

enum SubsStatus {
  processing('Готовим субтитры'),
  ready('Субтитры готовы'),
  failed('Субтитры не готовы');

  const SubsStatus(this.label);
  final String label;
}

/// Ролик, который пользователь добавил сам.
class MyVideo {
  MyVideo(this.video, {this.status = SubsStatus.processing});
  final Video video;
  SubsStatus status;

  Map<String, dynamic> toJson() => {
    'id': video.id,
    'title': video.title,
    'channel': video.channel,
    'status': status.name,
  };
  static MyVideo fromJson(Map<String, dynamic> j) => MyVideo(
    Video(id: j['id'], title: j['title'] ?? '', channel: j['channel'] ?? '', mine: true),
    status: SubsStatus.values.asNameMap()[j['status']] ?? SubsStatus.processing,
  );
}

/// Сохранённые слова, свои ролики, вход и настройки — общие для всех экранов.
class AppStore extends ChangeNotifier {
  SharedPreferences? _prefs;
  List<SavedWord> words = [];
  List<MyVideo> myVideos = [];
  bool cyr = false, dark = false;

  /// Онбординг пройден; показываем его один раз.
  bool onboarded = false;

  /// Почта вошедшего пользователя; null — не вошёл.
  String? user;

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    cyr = prefs.getString('kap.script') == 'cyr';
    dark = prefs.getString('kap.theme') == 'dark';
    onboarded = prefs.getBool('kap.onboarded') ?? false;
    user = prefs.getString('kap.user');
    words = (jsonDecode(prefs.getString('kap.words') ?? '[]') as List)
        .map((e) => SavedWord.fromJson(e as Map<String, dynamic>))
        .toList();
    myVideos = (jsonDecode(prefs.getString('kap.my') ?? '[]') as List)
        .map((e) => MyVideo.fromJson(e as Map<String, dynamic>))
        .toList();
    notifyListeners();
    // Генерация могла оборваться вместе с приложением — запускаем её заново.
    for (final m in myVideos.where((m) => m.status == SubsStatus.processing).toList()) {
      generateSubs(m.video.id);
    }
  }

  String conv(String s) => cyr ? toCyr(s) : toLat(s);
  bool isSaved(String key) => words.any((x) => x.key == key);

  void add(SavedWord w) {
    if (isSaved(w.key)) return;
    words.add(w);
    _saveWords();
  }

  void remove(String key) {
    words.removeWhere((x) => x.key == key);
    _saveWords();
  }

  void setCyr(bool v) {
    cyr = v;
    _prefs?.setString('kap.script', v ? 'cyr' : 'lat');
    notifyListeners();
  }

  void setDark(bool v) {
    dark = v;
    _prefs?.setString('kap.theme', v ? 'dark' : 'light');
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    _prefs?.setBool('kap.onboarded', true);
    notifyListeners();
  }

  // Авторизация замокана: бэкенда нет, вход просто запоминает почту на устройстве.
  void signIn(String email) {
    user = email;
    _prefs?.setString('kap.user', email);
    notifyListeners();
  }

  /// Слова и свои ролики остаются на устройстве. После выхода снова показываем онбординг.
  void signOut() {
    user = null;
    onboarded = false;
    _prefs?.remove('kap.user');
    _prefs?.remove('kap.onboarded');
    notifyListeners();
  }

  // ---- свои ролики ----
  // Список и распознанный текст хранятся только на этом устройстве (SharedPreferences)
  // и не попадают ни в общий каталог, ни к другим пользователям.

  MyVideo? myVideo(String id) {
    for (final m in myVideos) {
      if (m.video.id == id) return m;
    }
    return null;
  }

  void addVideo(Video v) {
    if (myVideo(v.id) != null) return;
    myVideos.add(MyVideo(v));
    _saveMy();
    generateSubs(v.id);
  }

  void removeVideo(String id) {
    myVideos.removeWhere((m) => m.video.id == id);
    _prefs?.remove('kap.subs.$id');
    _saveMy();
  }

  Future<void> generateSubs(String id) async {
    _setStatus(id, SubsStatus.processing);
    try {
      final g = await subsGenerator.generate(id);
      // Пока ждали, ролик могли удалить.
      if (myVideo(id) == null) return;
      await _prefs?.setString('kap.subs.$id', jsonEncode({'sr': g.sr, 'ru': g.ru, 'dict': g.dict}));
      _setStatus(id, SubsStatus.ready);
    } catch (_) {
      _setStatus(id, SubsStatus.failed);
    }
  }

  void _setStatus(String id, SubsStatus s) {
    final m = myVideo(id);
    if (m == null || m.status == s) return;
    m.status = s;
    _saveMy();
  }

  /// Субтитры и словарик ролика: у роликов из каталога — из assets, у своих — сохранённые на устройстве.
  Future<GeneratedSubs?> loadSubs(Video v) async {
    if (!v.mine) {
      return GeneratedSubs(
        sr: await rootBundle.loadString('assets/${v.id}.sr.vtt'),
        ru: await rootBundle.loadString('assets/${v.id}.ru.vtt'),
        dict: jsonDecode(await rootBundle.loadString('assets/${v.id}.dict.json')) as Map<String, dynamic>,
      );
    }
    final raw = _prefs?.getString('kap.subs.${v.id}');
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return GeneratedSubs(sr: j['sr'], ru: j['ru'], dict: j['dict'] as Map<String, dynamic>);
  }

  void _saveMy() {
    _prefs?.setString('kap.my', jsonEncode(myVideos));
    notifyListeners();
  }

  void _saveWords() {
    _prefs?.setString('kap.words', jsonEncode(words));
    notifyListeners();
  }
}

final store = AppStore();
