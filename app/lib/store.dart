import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics.dart';
import 'l10n.dart';
import 'stories_page.dart';
import 'subs.dart';
import 'subs_generator.dart';
import 'supabase_config.dart';
import 'videos.dart';

class SavedWord {
  SavedWord({
    required this.key,
    required this.tr,
    required this.ctx,
    required this.t,
    required this.video,
    this.lemma,
    this.lemmaTr = '',
    this.form,
    this.learned = false,
    this.starred = false,
  });
  final String key, tr, ctx, video;

  /// Слово выучено: отмечено «Знаю» в карточках. Такие слова не попадают в колоду.
  bool learned;

  /// Слово отмечено звёздочкой как избранное.
  bool starred;
  final double t;

  /// Начальная форма (им. п. ед. ч., инфинитив) и её перевод. null — ещё не определена.
  String? lemma;
  String lemmaTr;

  /// Чем слово является по отношению к начальной форме: «Винительный падеж», «3 лицо мн. числа». '' — ничем / неизвестно.
  String? form;

  Map<String, dynamic> toJson() => {
    'key': key,
    'tr': tr,
    'ctx': ctx,
    't': t,
    'video': video,
    if (lemma != null) 'lemma': lemma,
    if (lemmaTr.isNotEmpty) 'lemmaTr': lemmaTr,
    if (form != null) 'form': form,
    if (learned) 'learned': true,
    if (starred) 'starred': true,
  };
  static SavedWord fromJson(Map<String, dynamic> j) => SavedWord(
    key: j['key'],
    tr: j['tr'] ?? '',
    ctx: j['ctx'] ?? '',
    t: (j['t'] as num).toDouble(),
    video: j['video'] ?? '',
    lemma: j['lemma'],
    lemmaTr: j['lemmaTr'] ?? '',
    form: j['form'],
    learned: j['learned'] == true,
    starred: j['starred'] == true,
  );

  /// Заполняет [lemma] по записи словарика: заметка вида «pas; вин. падеж» называет начальную форму,
  /// а заметка без неё («сущ. м. р.», «инфинитив», «наречие») значит, что слово уже в начальной форме.
  /// Начальная форма слова по заметке словарика («biti — быть» → biti); без указания — само слово.
  static String lemmaOf(String key, String note) {
    final m = RegExp(r"^([\p{L}'-]+)(?:\s*\(se\))?\s*(?:$|[;—–,:(])", unicode: true).firstMatch(note);
    final head = m?.group(1)?.toLowerCase();
    // В английских заметках часть речи тоже латиницей («noun, masc.»), поэтому её отличаем по списку.
    final isLatin = head != null && RegExp(r'^[a-zčćžšđ]', unicode: true).hasMatch(head) && !_enPos.contains(head);
    return isLatin ? toLat(head) : key;
  }

  void setLemmaFrom(Map<String, dynamic> dict) {
    final entry = dict[key] as List?;
    final note = entry != null && entry.length > 1 ? entry[1] as String : '';
    lemma = lemmaOf(key, note);
    final own = lemma == key ? tr : '';
    final other = dict[lemma] as List?;
    lemmaTr = other != null ? other[0] as String : own;
    form = lemma == key ? '' : describeForm(note);
  }

  static const _cases = {
    'им': 'именительный',
    'род': 'родительный',
    'дат': 'дательный',
    'вин': 'винительный',
    'твор': 'творительный',
    'тв': 'творительный',
    'предл': 'предложный',
    'зват': 'звательный',
  };

  static const _enPos = {
    'noun',
    'verb',
    'adj',
    'adjective',
    'adv',
    'adverb',
    'prep',
    'preposition',
    'conj',
    'conjunction',
    'pron',
    'pronoun',
    'num',
    'numeral',
    'particle',
    'interj',
    'interjection',
    'infinitive',
    'participle',
    'phrase',
    'idiom',
  };

  /// Английская заметка («pas; acc. case, pl.») приводится к русской, по которой разбирает [describeForm].
  static String _enNoteToRu(String n) {
    final i = n.indexOf(RegExp(r'[;—–,:(]'));
    if (i < 0) return n;
    var t = n.substring(i);
    const cases = {
      'nom': 'им',
      'gen': 'род',
      'dat': 'дат',
      'acc': 'вин',
      'instr': 'твор',
      'loc': 'предл',
      'voc': 'зват',
    };
    t = t.replaceAllMapped(RegExp(r'\b(nom|gen|dat|acc|instr|loc|voc)\b\.?(\s*case)?'), (m) {
      return '${cases[m[1]]}. ${m[2] != null ? 'падеж' : ''}';
    });
    t = t
        .replaceAll(RegExp(r'\b(plural|pl)\b\.?'), 'мн. ч.')
        .replaceAll(RegExp(r'\b(singular|sg)\b\.?'), 'ед. ч.')
        .replaceAllMapped(RegExp(r'\b([123])(?:st|nd|rd)\s*pers(?:on)?\b\.?'), (m) => '${m[1]} л.')
        .replaceAll(RegExp(r'\bpast\b'), 'прош. вр')
        .replaceAll(RegExp(r'\bfuture\b'), 'буд. вр')
        .replaceAll(RegExp(r'\bimperative\b'), 'повел. накл')
        .replaceAll(RegExp(r'\bconditional\b'), 'сослагат')
        .replaceAll(RegExp(r'\bsuperlative\b'), 'превосх')
        .replaceAll(RegExp(r'\bcomparative\b'), 'сравн')
        .replaceAll(RegExp(r'\bmasc(uline)?\b\.?'), 'м. р.')
        .replaceAll(RegExp(r'\bfem(inine)?\b\.?'), 'ж. р.')
        .replaceAll(RegExp(r'\bneut(er)?\b\.?'), 'ср. р.');
    return n.substring(0, i) + t;
  }

  /// Разбирает заметку словарика («pas; вин. падеж», «biti, 3 л. мн. ч.») в короткое описание формы.
  /// Результат всегда русский: на язык интерфейса его переводит [formUi].
  static String describeForm(String note) {
    var n = _enNoteToRu(note.toLowerCase());
    n = n.replaceAll(RegExp(r'\([^)]*\)|[«"][^»"]*[»"]'), ' ');
    final colon = n.indexOf(':');
    if (colon > 0) n = n.substring(0, colon);
    final parts = <String>[];
    final cm = RegExp(r'((?:(?:им|род|дат|вин|твор|тв|предл|зват)\.?\s*/?\s*)+)\s*падеж', unicode: true).firstMatch(n);
    final person = RegExp(r'([123])\s*л\.').firstMatch(n);
    final plural = RegExp(r'мн\.\s*ч\.').hasMatch(n);
    final singular = RegExp(r'ед\.\s*ч\.').hasMatch(n);
    if (cm != null) {
      final names = RegExp(
        r'[а-я]+',
        unicode: true,
      ).allMatches(cm.group(1)!).map((m) => _cases[m.group(0)]).whereType<String>().toList();
      if (names.isNotEmpty) parts.add('${names.join('/')} падеж');
    }
    if (n.contains('аорист')) parts.add('аорист');
    if (n.contains('имперфект')) parts.add('имперфект');
    if (n.contains('прош. вр')) parts.add('прошедшее время');
    if (n.contains('буд. вр')) parts.add('будущее время');
    if (n.contains('повел. накл')) parts.add('повелительное наклонение');
    if (n.contains('сослагат') || n.contains('условн')) parts.add('сослагательное наклонение');
    if (n.contains('превосх')) {
      parts.add('превосходная степень');
    } else if (n.contains('сравн')) {
      parts.add('сравнительная степень');
    }
    if (person != null) {
      parts.add(
        '${person.group(1)} лицо ${plural
                ? 'мн. числа'
                : singular
                ? 'ед. числа'
                : ''}'
            .trim(),
      );
    } else if (plural) {
      parts.add('мн. число');
    } else if (singular) {
      parts.add('ед. число');
    }
    final g = RegExp(r'(?<![а-я])([мжс]|ср)\.\s*р\.', unicode: true).firstMatch(n);
    if (g != null) parts.add({'м': 'муж. род', 'ж': 'жен. род', 'с': 'ср. род', 'ср': 'ср. род'}[g.group(1)]!);
    if (parts.isEmpty) return 'Форма';
    final s = parts.join(', ');
    return s[0].toUpperCase() + s.substring(1);
  }
}

enum SubsStatus {
  processing('Готовим субтитры'),
  ready('Субтитры готовы'),
  failed('Субтитры не готовы');

  const SubsStatus(this._label);
  final String _label;
  String get label => ui(_label);
}

/// Ролик, который пользователь добавил сам.
class MyVideo {
  MyVideo(this.video, {this.status = SubsStatus.processing, DateTime? added}) : added = added ?? DateTime.now();
  final Video video;
  SubsStatus status;

  /// Почему не вышло: текст ошибки от воркера или приложения, показывается на экране ролика.
  String? error;

  /// Когда ролик добавлен: от этого момента на экране ролика считается оставшееся время.
  DateTime added;

  Map<String, dynamic> toJson() => {
    'id': video.id,
    'title': video.title,
    'channel': video.channel,
    'status': status.name,
    'added': added.toIso8601String(),
  };
  static MyVideo fromJson(Map<String, dynamic> j) => MyVideo(
    Video(id: j['id'], title: j['title'] ?? '', channel: j['channel'] ?? '', mine: true),
    status: SubsStatus.values.asNameMap()[j['status']] ?? SubsStatus.processing,
    added: DateTime.tryParse(j['added'] ?? ''),
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

  /// Id роликов со звёздочкой, последний отмеченный — в конце.
  List<String> liked = [];

  /// Секунда, на которой остановились в ролике; досмотренных роликов здесь нет.
  Map<String, double> positions = {};

  /// Просмотренная доля ролика, 0..1; у досмотренного — 1.
  Map<String, double> progress = {};

  /// Результаты заданий: «ролик/раздел» → [верных ответов, всего вопросов]. Хранятся только на устройстве.
  Map<String, List<int>> quiz = {};
  /// Сколько разделов заданий у ролика (запоминаем, когда его открывали).
  Map<String, int> quizCount = {};
  bool cyr = false, dark = false;

  /// Какие строки субтитров показывать в плеере: сербские и русские.
  bool showSr = true, showRu = true;

  /// Язык интерфейса и перевода: 'ru' или 'en'.
  String lang = defaultLang();

  /// Онбординг пройден; показываем его один раз.
  bool onboarded = false;

  /// Ответы анкеты после онбординга: уровень ('A', 'B1', 'B2') и любимые темы. Пусто — анкету пропустили.
  String? level;
  List<String> interests = [];

  /// Анкету прошли или пропустили; показываем её один раз.
  bool surveyDone = false;

  /// Почта вошедшего пользователя; null — не вошёл.
  String? user;

  /// Фото и имя из аккаунта Google; при входе по коду из письма их нет.
  String? get avatarUrl {
    final m = cloud?.auth.currentUser?.userMetadata;
    return (m?['avatar_url'] ?? m?['picture']) as String?;
  }

  String? get fullName => cloud?.auth.currentUser?.userMetadata?['full_name'] as String?;

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    try {
      _stress = jsonDecode(await rootBundle.loadString('assets/stress.json')) as Map<String, dynamic>;
    } catch (_) {}
    cyr = prefs.getString('kap.script') == 'cyr';
    dark = prefs.getString('kap.theme') == 'dark';
    showSr = prefs.getBool('kap.showSr') ?? true;
    showRu = prefs.getBool('kap.showRu') ?? true;
    lang = prefs.getString('kap.lang') ?? defaultLang();
    uiLang = lang;
    onboarded = prefs.getBool('kap.onboarded') ?? false;
    level = prefs.getString('kap.level');
    interests = prefs.getStringList('kap.interests') ?? [];
    surveyDone = prefs.getBool('kap.survey') ?? false;
    user = cloud?.auth.currentUser?.email;
    cloud?.auth.onAuthStateChange.listen((s) {
      final email = s.session?.user.email;
      if (s.event == AuthChangeEvent.signedIn) identifyUser(s.session?.user.id);
      if (s.event == AuthChangeEvent.signedOut) identifyUser(null);
      if (s.event == AuthChangeEvent.signedIn && user == null && email != null) {
        // Ввели код или открыли ссылку из письма.
        user = email;
        final created = DateTime.tryParse(s.session?.user.createdAt ?? '');
        if (created != null && DateTime.now().difference(created).inMinutes < 15) {
          trackEvent('signup', {'method': s.session?.user.appMetadata['provider']?.toString() ?? 'unknown'});
        }
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
    quiz = (jsonDecode(prefs.getString('kap.quiz') ?? '{}') as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as List).cast<int>()),
    );
    quizCount = (jsonDecode(prefs.getString('kap.quizCount') ?? '{}') as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
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

  /// Ударения (assets/stress.json: слово латиницей → оно же с острым над ударной гласной), грузятся при старте.
  Map<String, dynamic> _stress = {};

  /// Слово в выбранной письменности, с ударением, если оно известно.
  String stressed(String s) {
    final lat = toLat(s);
    final st = _stress[lat.toLowerCase()] as String?;
    if (st == null) return conv(s);
    return conv(lat[0] != lat[0].toLowerCase() ? st[0].toUpperCase() + st.substring(1) : st);
  }
  bool isSaved(String key) => words.any((x) => x.key == key);

  void add(SavedWord w) {
    if (isSaved(w.key)) return;
    words.add(w);
    _saveWords();
    trackEvent('word_saved', {'video_id': w.video});
  }

  void setLearned(String key, bool v) {
    for (final w in words) {
      if (w.key == key) w.learned = v;
    }
    _saveWords();
  }

  void toggleStar(String key) {
    for (final w in words) {
      if (w.key == key) w.starred = !w.starred;
    }
    _saveWords();
  }

  void remove(String key) {
    words.removeWhere((x) => x.key == key);
    _saveWords();
  }

  /// Дописывает начальную форму у слов, сохранённых до того, как она появилась.
  Future<void> fillLemmas() async {
    final todo = words.where((w) => w.lemma == null || w.form == null).toList();
    if (todo.isEmpty) return;
    final byVideo = <String, List<SavedWord>>{};
    for (final w in todo) {
      (byVideo[w.video] ??= []).add(w);
    }
    for (final e in byVideo.entries) {
      Map<String, dynamic>? dict;
      try {
        final story = storyById(e.key);
        final video = videoById(e.key);
        if (story?.asset != null) {
          dict = jsonDecode(
            await assetText('${story!.asset}.dict.json', en: '${story.asset}.dict.en.json'),
          ) as Map<String, dynamic>;
        } else if (video != null) {
          dict = (await loadSubs(video))?.dict;
        }
      } catch (_) {}
      for (final w in e.value) {
        if (dict != null) {
          w.setLemmaFrom(dict);
        } else {
          w.lemma ??= w.key;
          if (w.lemma == w.key) w.lemmaTr = w.tr;
          w.form ??= w.lemma == w.key ? '' : 'Форма';
        }
      }
    }
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

  // ---- задания ----

  List<int>? quizResult(String videoId, String section) => quiz['$videoId/$section'];

  void setQuizCount(String videoId, int n) {
    if (quizCount[videoId] == n) return;
    quizCount[videoId] = n;
    _prefs?.setString('kap.quizCount', jsonEncode(quizCount));
    notifyListeners();
  }

  /// Ролик просмотрен и все его задания выполнены.
  bool isFinished(String videoId) {
    final n = quizCount[videoId];
    if (n == null || !isWatched(videoId)) return false;
    final done = quiz.keys.where((k) => k.startsWith('$videoId/')).length;
    return done >= n;
  }

  void setQuizResult(String videoId, String section, int right, int total) {
    quiz['$videoId/$section'] = [right, total];
    trackEvent('quiz_completed', {'video_id': videoId, 'section': section, 'right': right, 'total': total});
    _prefs?.setString('kap.quiz', jsonEncode(quiz));
    notifyListeners();
  }

  // ---- звёздочки ----

  bool isLiked(String videoId) => liked.contains(videoId);

  void toggleLike(String videoId) {
    final added = !liked.remove(videoId);
    if (added) {
      liked.add(videoId);
      trackEvent('video_liked', {'video_id': videoId});
    }
    _saveLiked();
  }

  void setCyr(bool v) {
    cyr = v;
    _prefs?.setString('kap.script', v ? 'cyr' : 'lat');
    notifyListeners();
  }

  void setShowSr(bool v) {
    showSr = v;
    _prefs?.setBool('kap.showSr', v);
    notifyListeners();
  }

  void setShowRu(bool v) {
    showRu = v;
    _prefs?.setBool('kap.showRu', v);
    notifyListeners();
  }

  void setLang(String v) {
    if (v == lang) return;
    lang = uiLang = v;
    _prefs?.setString('kap.lang', v);
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

  /// Сохраняет ответы анкеты; без аргументов — анкету пропустили.
  void finishSurvey({String? level, List<String> interests = const []}) {
    this.level = level;
    this.interests = [...interests];
    surveyDone = true;
    level == null ? _prefs?.remove('kap.level') : _prefs?.setString('kap.level', level);
    _prefs?.setStringList('kap.interests', this.interests);
    _prefs?.setBool('kap.survey', true);
    notifyListeners();
    _touch();
  }

  /// Для проверки: снова показывает лендинг (только веб), не трогая анкету.
  void replayLanding() {
    onboarded = false;
    _prefs?.remove('kap.onboarded');
    notifyListeners();
  }

  /// Пасхалка: показывает онбординг и анкету заново, остальное на устройстве не трогает.
  void replayOnboarding() {
    onboarded = false;
    surveyDone = false;
    _prefs?.remove('kap.onboarded');
    _prefs?.remove('kap.survey');
    notifyListeners();
  }

  // ---- каталог ----

  /// Берёт свежий каталог из облака и запоминает его, чтобы без сети открыться с ним же.
  Future<void> _refreshCatalog() async {
    try {
      final catalog = {
        // Все столбцы: kind появился позже остальных, и в старой базе его может не быть.
        'videos': await cloud!.from('videos').select().order('sort', ascending: true),
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
      cloud!.auth.signInWithOtp(email: email, emailRedirectTo: _redirect);

  // В вебе возвращаемся на ту же страницу, иначе Supabase отправит на Site URL.
  String get _redirect => kIsWeb ? Uri(scheme: Uri.base.scheme, host: Uri.base.host, port: Uri.base.hasPort ? Uri.base.port : null, path: Uri.base.path).toString() : authRedirect;

  // Откроется браузер, сессия придёт обратно по ссылке и поймается в onAuthStateChange.
  Future<void> signInWithGoogle() =>
      cloud!.auth.signInWithOAuth(OAuthProvider.google, redirectTo: _redirect);

  Future<void> verifyCode(String email, String code) =>
      cloud!.auth.verifyOTP(email: email, token: code, type: OtpType.email);

  /// Удаляет аккаунт и облачные данные (функция delete_my_account, см. supabase/delete_account.sql), потом выходит.
  Future<void> deleteAccount() async {
    await cloud!.rpc('delete_my_account');
    await signOut();
  }

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
  // У вошедшего в облаке лежит одна строка user_data: слова, звёздочки, история и прогресс.
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
    await _pushProfile();
  }

  /// Анкета лежит отдельным запросом: пока в облаке нет колонок (supabase/profile.sql), остальное не страдает.
  Future<void> _pushProfile() async {
    final uid = cloud?.auth.currentUser?.id;
    if (uid == null || !surveyDone) return;
    try {
      await cloud!.from('user_data').upsert({
        'user_id': uid,
        'level': level,
        'interests': interests,
        'survey_done': true,
      });
    } catch (_) {}
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
      // Анкету, пройденную на другом устройстве, не спрашиваем заново.
      if (row['survey_done'] == true && !surveyDone) {
        surveyDone = true;
        level = row['level'] as String?;
        interests = ((row['interests'] as List?) ?? const []).cast<String>();
        level == null ? _prefs?.remove('kap.level') : _prefs?.setString('kap.level', level!);
        _prefs?.setStringList('kap.interests', interests);
        _prefs?.setBool('kap.survey', true);
      } else if (surveyDone && row['survey_done'] != true) {
        unawaited(_pushProfile());
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
    // Заявку тоже снимаем, чтобы воркер не готовил то, что уже не нужно.
    if (cloud != null) unawaited(Future(() => cloud!.from('video_requests').delete().eq('id', id)).catchError((_) {}));
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
    final retry = myVideo(id)?.status == SubsStatus.failed;
    if (retry)
      myVideo(id)!
        ..added = DateTime.now()
        ..error = null;
    _setStatus(id, SubsStatus.processing);
    try {
      final g = await subsGenerator.generate(myVideo(id)!.video, retry: retry);
      // Пока ждали, ролик могли удалить.
      if (myVideo(id) == null) return;
      await _prefs?.setString('kap.subs.$id', jsonEncode({'sr': g.sr, 'ru': g.ru, 'dict': g.dict}));
      _setStatus(id, SubsStatus.ready);
    } catch (e) {
      myVideo(id)?.error = e.toString().replaceFirst('Bad state: ', '');
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
          ru: await assetText('${v.id}.ru.vtt', en: '${v.id}.en.vtt'),
          dict: jsonDecode(await assetText('${v.id}.dict.json', en: '${v.id}.dict.en.json')) as Map<String, dynamic>,
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

  /// Текст из assets. При английском интерфейсе берём английский файл [en], а если перевода на английский ещё нет —
  /// русский [ru]: так ролики, которые не успели перевести, остаются доступными.
  Future<String> assetText(String ru, {required String en}) async {
    if (lang == 'en') {
      try {
        return await rootBundle.loadString('assets/$en');
      } catch (_) {}
    }
    return rootBundle.loadString('assets/$ru');
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
