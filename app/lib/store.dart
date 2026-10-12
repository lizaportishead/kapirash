import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'subs.dart';
import 'subs_generator.dart';
import 'supabase_config.dart';
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

/// Клиент Supabase; null — облако не подключено, и всё живёт только на устройстве.
SupabaseClient? cloud;

/// Сохранённые слова, свои ролики, вход и настройки — общие для всех экранов.
class AppStore extends ChangeNotifier {
  SharedPreferences? _prefs;
  List<SavedWord> words = [];
  List<MyVideo> myVideos = [];

  /// Id открытых роликов, последний открытый — в конце.
  List<String> history = [];

  /// Id роликов с сердечком, последний отмеченный — в конце.
  List<String> liked = [];

  /// Секунда, на которой остановились в ролике; досмотренных роликов здесь нет.
  Map<String, double> positions = {};

  /// Просмотренная доля ролика, 0..1; у досмотренного — 1.
  Map<String, double> progress = {};
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
    user = cloud?.auth.currentUser?.email;
    cloud?.auth.onAuthStateChange.listen((s) {
      final email = s.session?.user.email;
      if (s.event == AuthChangeEvent.signedIn && user == null && email != null) {
        // Ввели код или открыли ссылку из письма.
        user = email;
        notifyListeners();
        unawaited(_sync(merge: true));
      } else if (s.event == AuthChangeEvent.signedOut && user != null) {
        // Сессию могли отозвать, или она истекла — тогда выходим и на устройстве.
        user = null;
        notifyListeners();
      }
    });
    words = (jsonDecode(prefs.getString('kap.words') ?? '[]') as List)
        .map((e) => SavedWord.fromJson(e as Map<String, dynamic>))
        .toList();
    myVideos = (jsonDecode(prefs.getString('kap.my') ?? '[]') as List)
        .map((e) => MyVideo.fromJson(e as Map<String, dynamic>))
        .toList();
    history = (jsonDecode(prefs.getString('kap.history') ?? '[]') as List).cast<String>();
    liked = (jsonDecode(prefs.getString('kap.liked') ?? '[]') as List).cast<String>();
    positions = (jsonDecode(prefs.getString('kap.pos') ?? '{}') as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    progress = (jsonDecode(prefs.getString('kap.progress') ?? '{}') as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final catalog = prefs.getString('kap.catalog');
    if (catalog != null) setCatalog(jsonDecode(catalog) as Map<String, dynamic>);
    notifyListeners();
    if (cloud != null) unawaited(_refreshCatalog());
    // Генерация могла оборваться вместе с приложением — запускаем её заново.
    for (final m in myVideos.where((m) => m.status == SubsStatus.processing).toList()) {
      generateSubs(m.video.id);
    }
    if (user != null) unawaited(_sync(merge: prefs.getBool('kap.dirty') ?? false));
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

  int wordCount(String videoId) => words.where((w) => w.video == videoId).length;

  // ---- история ----

  bool isWatched(String videoId) => history.contains(videoId);

  /// Ролик считается просмотренным, как только его открыли.
  void markWatched(String videoId) {
    if (history.isNotEmpty && history.last == videoId) return;
    history
      ..remove(videoId)
      ..add(videoId);
    _saveHistory();
  }

  // ---- место остановки ----

  double? positionOf(String videoId) => positions[videoId];

  /// null — ролик досмотрен, в следующий раз начнём сначала.
  // Экраны позицию не показывают, поэтому слушателей не будим: плеер зовёт это каждые несколько секунд.
  void setPosition(String videoId, double? t) {
    if (positions[videoId] == t) return;
    t == null ? positions.remove(videoId) : positions[videoId] = t;
    _prefs?.setString('kap.pos', jsonEncode(positions));
    _touch();
  }

  // ---- шкала просмотра ----

  /// Доля для шкалы на превью. У роликов, открытых до появления шкалы, считаем её по месту остановки.
  double progressOf(Video v) {
    final p = progress[v.id];
    if (p != null) return p;
    final t = positions[v.id];
    final total = v.duration.split(':').fold(0, (s, x) => s * 60 + (int.tryParse(x) ?? 0));
    return t == null || total == 0 ? 0 : (t / total).clamp(0, 1).toDouble();
  }

  /// Плеер зовёт это каждые несколько секунд, поэтому слушателей будим только по [notify] — при выходе из ролика.
  // Выход — это dispose, дерево в этот момент заперто, так что будим после него.
  void setProgress(String videoId, double p, {bool notify = false}) {
    if (progress[videoId] != p) {
      progress[videoId] = p;
      _prefs?.setString('kap.progress', jsonEncode(progress));
      _touch();
    }
    if (notify) scheduleMicrotask(notifyListeners);
  }

  // ---- сердечки ----

  bool isLiked(String videoId) => liked.contains(videoId);

  void toggleLike(String videoId) {
    if (!liked.remove(videoId)) liked.add(videoId);
    _saveLiked();
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

  /// Пасхалка: показывает онбординг заново, остальное на устройстве не трогает.
  void replayOnboarding() {
    onboarded = false;
    _prefs?.remove('kap.onboarded');
    notifyListeners();
  }

  // ---- каталог ----

  /// Берёт свежий каталог из облака и запоминает его, чтобы без сети открыться с ним же.
  Future<void> _refreshCatalog() async {
    try {
      final catalog = {
        'videos': await cloud!.from('videos').select('id,title,channel,topic,level,duration').order('sort'),
        'creators': await cloud!.from('creators').select(),
      };
      // Пустой каталог — скорее ошибка настройки, чем правда: остаёмся с прежним.
      if ((catalog['videos'] as List).isEmpty) return;
      setCatalog(catalog);
      _prefs?.setString('kap.catalog', jsonEncode(catalog));
      notifyListeners();
    } catch (_) {
      // Нет сети или таблиц — остаёмся с прежним каталогом.
    }
  }

  // ---- вход ----
  // Входим по письму — ссылкой или кодом, см. [kEmailCode]. Пароля нет, аккаунт заводится при первом входе.

  bool get canSignIn => cloud != null;

  // В вебе ссылка ведёт на Site URL проекта.
  Future<void> sendCode(String email) =>
      cloud!.auth.signInWithOtp(email: email, emailRedirectTo: kIsWeb ? null : authRedirect);

  Future<void> verifyCode(String email, String code) =>
      cloud!.auth.verifyOTP(email: email, token: code, type: OtpType.email);

  /// Слова и свои ролики остаются на устройстве, приложением можно пользоваться и без входа.
  Future<void> signOut() async {
    user = null;
    notifyListeners();
    // Сначала досылаем несохранённое: после выхода писать в облако уже нельзя.
    if (_pushTimer?.isActive ?? false) await _push();
    _pushTimer?.cancel();
    await cloud?.auth.signOut();
  }

  // ---- облако ----
  // У вошедшего в облаке лежит одна строка user_data: слова, сердечки, история и прогресс.
  // Свои ролики и их субтитры остаются на устройстве.

  Timer? _pushTimer;
  int _rev = 0;

  /// Отмечает, что на устройстве есть неотправленное, и вскоре отправляет.
  void _touch() {
    if (user == null) return;
    _rev++;
    _prefs?.setBool('kap.dirty', true);
    _pushTimer?.cancel();
    _pushTimer = Timer(Duration(seconds: 3), _push);
  }

  Future<void> _push() async {
    final uid = cloud?.auth.currentUser?.id;
    if (uid == null) return;
    final rev = _rev;
    try {
      await cloud!.from('user_data').upsert({
        'user_id': uid,
        'words': words.map((w) => w.toJson()).toList(),
        'liked': liked,
        'history': history,
        'positions': positions,
        'progress': progress,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (rev == _rev) _prefs?.setBool('kap.dirty', false);
    } catch (_) {
      // Нет сети — отправим при следующем изменении или запуске.
    }
  }

  /// [merge] — на устройстве есть своё (только что вошли или не успели отправить), складываем его с облаком.
  /// Иначе в облаке свежее, и оно заменяет то, что на устройстве.
  Future<void> _sync({required bool merge}) async {
    final rev = _rev;
    final Map<String, dynamic>? row;
    try {
      row = await cloud!.from('user_data').select().maybeSingle();
    } catch (_) {
      return;
    }
    // Пока ждали ответ, на устройстве что-то поменяли.
    merge = merge || rev != _rev;
    if (row != null) {
      Map<String, double> nums(String k) =>
          (row![k] as Map<String, dynamic>).map((id, v) => MapEntry(id, (v as num).toDouble()));
      final rWords = (row['words'] as List).map((e) => SavedWord.fromJson(e as Map<String, dynamic>)).toList();
      final rLiked = (row['liked'] as List).cast<String>(), rHistory = (row['history'] as List).cast<String>();
      final rPos = nums('positions'), rProgress = nums('progress');
      if (merge) {
        words = [...rWords, ...words.where((w) => !rWords.any((r) => r.key == w.key))];
        liked = {...rLiked, ...liked}.toList();
        history = [...rHistory.where((id) => !history.contains(id)), ...history];
        positions = {...rPos, ...positions};
        progress = {...rProgress, for (final e in progress.entries) e.key: max(e.value, rProgress[e.key] ?? 0)};
      } else {
        words = rWords;
        liked = rLiked;
        history = rHistory;
        positions = rPos;
        progress = rProgress;
      }
      _prefs
        ?..setString('kap.words', jsonEncode(words))
        ..setString('kap.liked', jsonEncode(liked))
        ..setString('kap.history', jsonEncode(history))
        ..setString('kap.pos', jsonEncode(positions))
        ..setString('kap.progress', jsonEncode(progress));
      notifyListeners();
    }
    if (merge || row == null) await _push();
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
    if (history.remove(id)) _prefs?.setString('kap.history', jsonEncode(history));
    if (liked.remove(id)) _prefs?.setString('kap.liked', jsonEncode(liked));
    setPosition(id, null);
    if (progress.remove(id) != null) _prefs?.setString('kap.progress', jsonEncode(progress));
    _touch();
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

  /// Субтитры и словарик ролика. У роликов из каталога — из assets, а если ролик появился после сборки —
  /// из облака, с копией на устройстве. У своих — сохранённые на устройстве.
  Future<GeneratedSubs?> loadSubs(Video v) async {
    if (!v.mine) {
      try {
        return GeneratedSubs(
          sr: await rootBundle.loadString('assets/${v.id}.sr.vtt'),
          ru: await rootBundle.loadString('assets/${v.id}.ru.vtt'),
          dict: jsonDecode(await rootBundle.loadString('assets/${v.id}.dict.json')) as Map<String, dynamic>,
        );
      } catch (_) {
        if (!(_prefs?.containsKey('kap.catalogSubs.${v.id}') ?? false) && !await _downloadSubs(v.id)) return null;
      }
    }
    final raw = _prefs?.getString(v.mine ? 'kap.subs.${v.id}' : 'kap.catalogSubs.${v.id}');
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return GeneratedSubs(sr: j['sr'], ru: j['ru'], dict: j['dict'] as Map<String, dynamic>);
  }

  Future<bool> _downloadSubs(String id) async {
    if (cloud == null) return false;
    try {
      final files = cloud!.storage.from('subs');
      Future<String> text(String ext) async => utf8.decode(await files.download('$id.$ext'));
      final subs = {
        'sr': await text('sr.vtt'),
        'ru': await text('ru.vtt'),
        'dict': jsonDecode(await text('dict.json')),
      };
      await _prefs?.setString('kap.catalogSubs.$id', jsonEncode(subs));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _saveMy() {
    _prefs?.setString('kap.my', jsonEncode(myVideos));
    notifyListeners();
  }

  void _saveHistory() {
    _prefs?.setString('kap.history', jsonEncode(history));
    _touch();
    notifyListeners();
  }

  void _saveLiked() {
    _prefs?.setString('kap.liked', jsonEncode(liked));
    _touch();
    notifyListeners();
  }

  void _saveWords() {
    _prefs?.setString('kap.words', jsonEncode(words));
    _touch();
    notifyListeners();
  }
}

final store = AppStore();
