import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'clips_page.dart';
import 'creator_page.dart';
import 'icons.dart';
import 'kap_loader.dart';
import 'phrase.dart';
import 'quiz_page.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'video_card.dart';
import 'processing_page.dart';
import 'videos.dart';
import 'l10n.dart';

/// Открывает плеер поверх таббара; у клипов из TikTok он свой, вертикальный.
void openVideo(BuildContext context, Video v, {double? startAt}) {
  if (v.tiktok) return openClip(context, v, startAt: startAt);
  // Свой ролик, пока субтитры не готовы, смотреть нельзя: показываем, как идёт подготовка.
  if (v.mine && store.myVideo(v.id)?.status != SubsStatus.ready) return openProcessing(context, v);
  store.markWatched(v.id);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlayerPage(video: v, startAt: startAt),
    ),
  );
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.video, this.startAt});
  final Video video;
  final double? startAt;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final YoutubePlayerController _yt;
  StreamSubscription<YoutubeVideoState>? _sub;
  List<Cue> _sr = [], _ru = [];
  bool _subsLoading = true;
  Map<String, dynamic> _dict = {};
  List<QuizSection> _quiz = [];
  // Переключатели SR/RU пока убраны с экрана: обе строки показываются всегда.
  final _showSr = true, _showRu = true;
  // Текущая фраза; за ней следит и открытый поверх плеера экран с полным текстом.
  final _curN = ValueNotifier<int>(-1);
  int get _cur => _curN.value;
  // Где сейчас плеер; null, пока ролик не запускали, — чтобы не затереть сохранённое место нулём.
  double? _pos;
  double _savedPos = -1;
  // Ключ не даёт плееру перезагрузиться, когда поворот экрана переставляет его в другую раскладку.
  final _playerKey = GlobalKey();
  // Вкладка боковой колонки на десктопе: 0 — текст, 1 — слова, 2 — задания.
  int _side = 0;

  // Кнопка «Мои слова» — сюда улетает шторка со словом.
  final _wordsKey = GlobalKey();
  String get videoId => widget.video.id;
  // На странице ролика — только слова, сохранённые из него.
  List<SavedWord> get _words => store.words.where((w) => w.video == videoId).toList();
  void _onStore() {
    setState(() {});
    // Субтитры своего ролика могут доготовиться, пока плеер открыт.
    if (_sr.isEmpty && widget.video.mine) _load();
  }

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _yt = YoutubePlayerController(
      params: YoutubePlayerParams(
        enableCaption: false,
        interfaceLanguage: 'ru',
        strictRelatedVideos: true,
        showFullscreenButton: true,
      ),
    );
    _cueVideo();
    _sub = _yt.videoStateStream.listen((s) => _onTime(s.position.inMilliseconds / 1000));
    _load();
    loadQuiz(videoId).then((q) {
      if (mounted && q.isNotEmpty) setState(() => _quiz = q);
    });
  }

  // Плеер в WebView может стартовать дольше 30 секунд, которые ждёт пакет, — тогда пробуем ещё раз.
  Future<void> _cueVideo() async {
    for (var i = 0; i < 6 && mounted; i++) {
      try {
        // Без явного места открываем там, где остановились в прошлый раз.
        await _yt.cueVideoById(videoId: videoId, startSeconds: widget.startAt ?? store.positionOf(videoId));
        return;
      } on TimeoutException {
        continue;
      }
    }
  }

  Future<void> _load() async {
    final subs = await store.loadSubs(widget.video);
    if (!mounted) return;
    if (subs == null) return setState(() => _subsLoading = false);
    setState(() {
      _subsLoading = false;
      _sr = parseSubs(subs.sr);
      _ru = parseSubs(subs.ru);
      _dict = subs.dict;
      if (_cur < 0 && _sr.isNotEmpty) _curN.value = 0;
    });
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _savePos(leaving: true);
    _sub?.cancel();
    _yt.close();
    _curN.dispose();
    super.dispose();
  }

  void _savePos({bool leaving = false}) {
    final t = _pos;
    if (t == null) return;
    final total = _yt.value.metaData.duration.inSeconds;
    // Досмотренный до конца (или почти) ролик в следующий раз начинаем сначала.
    final done = _yt.value.playerState == PlayerState.ended || (total > 0 && t > total - 5);
    store.setPosition(videoId, done ? null : t);
    // Шкала на превью: досмотренный ролик закрашен целиком.
    if (done || total > 0) store.setProgress(videoId, done ? 1 : t / total, notify: leaving);
    _savedPos = t;
  }

  void _onTime(double t) {
    if (_pos != null || _yt.value.playerState == PlayerState.playing) {
      _pos = t;
      // Приложение могут закрыть без dispose, поэтому сохраняем и по ходу просмотра.
      if ((t - _savedPos).abs() >= 5) _savePos();
    }
    if (_sr.isEmpty) return;
    var i = cueAt(_sr, t);
    if (i < 0) {
      for (var k = _sr.length - 1; k >= 0; k--) {
        if (_sr[k].start <= t) {
          i = k;
          break;
        }
      }
    }
    if (i < 0 || i == _cur) return;
    setState(() => _curN.value = i);
  }

  void _seek(double t) {
    _yt.seekTo(seconds: t < 0.15 ? 0 : t - 0.15, allowSeekAhead: true);
    _yt.playVideo();
  }

  void _step(int d) {
    if (_sr.isEmpty) return;
    final i = ((_cur < 0 ? 0 : _cur) + d).clamp(0, _sr.length - 1);
    _seek(_sr[i].start);
  }

  String _ruFor(Cue c) {
    final j = cueAt(_ru, (c.start + c.end) / 2);
    return j >= 0 ? _ru[j].text : '';
  }

  void _openWord(String raw, Cue cue) {
    if (cleanWord(raw).isEmpty) return;
    _yt.pauseVideo();
    showWord(context, raw: raw, cue: cue, dict: _dict, videoId: videoId, flyTo: _wordsKey);
  }

  @override
  Widget build(BuildContext context) {
    final cue = _cur >= 0 && _cur < _sr.length ? _sr[_cur] : null;
    final size = MediaQuery.sizeOf(context);
    // Свою раскладку показываем вместо полноэкранного режима плеера, поэтому autoFullScreen выключен.
    final player = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: YoutubePlayer(key: _playerKey, controller: _yt, autoFullScreen: false),
    );
    // На планшете и в горизонтальном положении хватает высоты для обычной раскладки.
    if (size.width > size.height && size.height < 600) return _landscape(player, cue);
    if (size.width >= 960) return _desktop(player, cue);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [_back(), Spacer(), _youtubeButton(), LikeButton(widget.video.id)]),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _avatar(),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.video.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                          color: cText,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      _channel(avatar: false),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          player,
                          SizedBox(height: 10),
                          _current(cue),
                          if (_quiz.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 28, 4, 8),
                              child: Text(
                                ui('Посмотри ролик и выполни задания'),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25, color: cText),
                              ),
                            ),
                            QuizList(videoId: videoId, sections: _quiz, inline: true),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  _links(),
                  SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Десктоп: слева видео и текущая фраза, справа — текст, слова и задания без переходов на другие экраны.
  Widget _desktop(Widget player, Cue? cue) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _back(),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 13, bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.video.title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                          color: cText,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      _channel(),
                                    ],
                                  ),
                                ),
                              ),
                              _youtubeButton(),
                              LikeButton(widget.video.id),
                            ],
                          ),
                          player,
                          SizedBox(height: 12),
                          _current(cue),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(padding: EdgeInsets.only(top: 12), child: _sidePanel()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidePanel() {
    final tabs = <(String, IconData)>[
      (ui('Текст'), KIcons.text),
      ('${ui('Слова')}${_words.isEmpty ? '' : ' · ${_words.length}'}', KIcons.wordsOn),
      if (_quiz.isNotEmpty) (ui('Задания'), KIcons.tasks),
    ];
    final tab = _side.clamp(0, tabs.length - 1);
    final Widget body = switch (tab) {
      0 when _subsLoading => KapLoading(size: 40),
      0 => Transcript(sr: _sr, cur: _curN, ruFor: _showRu ? _ruFor : (_) => '', onSeek: _seek, popOnTap: false),
      1 => WordList(videoId: videoId, onSeek: _seek, popOnTap: false),
      _ => QuizList(videoId: videoId, sections: _quiz),
    };
    return Container(
      decoration: BoxDecoration(color: cCard.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              spacing: 6,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: Pill(
                      tabs[i].$1,
                      icon: tabs[i].$2,
                      on: i == tab,
                      onTap: () {
                        if (i == 2) _yt.pauseVideo();
                        setState(() => _side = i);
                      },
                    ),
                  ),
              ],
            ),
          ),
          // KeyedSubtree сбрасывает прокрутку при смене вкладки.
          Expanded(
            child: KeyedSubtree(key: ValueKey(tab), child: body),
          ),
        ],
      ),
    );
  }

  // Горизонтальный телефон: видео как можно крупнее, под ним — только строка субтитров.
  Widget _landscape(Widget player, Cue? cue) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // По бокам от видео — чёрные поля до самых краёв экрана, как в полноэкранном плеере.
            child: ColoredBox(
              color: Colors.black,
              child: SafeArea(
                bottom: false,
                // Кнопка «назад» стоит сбоку от видео, где всё равно пусто; отступ справа держит видео по центру.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _back(color: cOnInk),
                    Expanded(child: Center(child: player)),
                    SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          // Высота постоянная, чтобы видео не прыгало от фразы к фразе.
          ColoredBox(
            color: cAccent,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.only(bottom: 4),
              child: SizedBox(
                height: 70,
                // Стрелки по бокам листают фразы, как кнопки под видео в вертикальном режиме.
                child: Row(
                  children: [
                    _stepArrow(-1),
                    Expanded(child: Center(child: _strip(cue))),
                    _stepArrow(1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepArrow(int d) {
    return IconButton(
      tooltip: d < 0 ? ui('Предыдущая фраза') : ui('Следующая фраза'),
      icon: Icon(d < 0 ? KIcons.arrowLeft : KIcons.arrowRight, size: 24, color: cInk),
      onPressed: () => _step(d),
    );
  }

  Widget _strip(Cue? cue) {
    if (cue == null) return SizedBox.shrink();
    final ru = _showRu ? _ruFor(cue) : '';
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSr) PhraseWords(cue, onWord: (w) => _openWord(w, cue), size: 16, spacing: 5, pad: 0, center: true),
          if (ru.isNotEmpty)
            Text(
              ru,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: cInk.withValues(alpha: 0.72),
              ),
            ),
        ],
      ),
    );
  }

  Widget _back({Color? color}) {
    return IconButton(
      tooltip: ui('Назад'),
      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: color ?? cText),
      onPressed: () => Navigator.pop(context),
    );
  }

  // Аватарка и имя автора; у чужих роликов ведут на страницу канала.
  Widget _channel({bool avatar = true}) {
    final name = widget.video.channel;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (avatar) ...[CreatorAvatar(name, size: 22), SizedBox(width: 7)],
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cMuted),
          ),
        ),
      ],
    );
    if (widget.video.mine) return row;
    return Semantics(
      button: true,
      label: ui('Канал {0}', [name]),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          _yt.pauseVideo();
          openCreator(context, name);
        },
        child: Padding(padding: EdgeInsets.symmetric(vertical: 3), child: row),
      ),
    );
  }

  // Круглая аватарка автора для мобильной шапки; как и имя, ведёт на страницу канала.
  Widget _avatar() {
    final name = widget.video.channel;
    final a = CreatorAvatar(name, size: 40);
    if (widget.video.mine) return a;
    return GestureDetector(
      onTap: () {
        _yt.pauseVideo();
        openCreator(context, name);
      },
      child: a,
    );
  }

  // Кнопки листают фразы, поэтому живут на карточке фразы — сверху, чтобы не прыгать вместе с её высотой.
  Widget _controls() {
    Widget button(int d, IconData icon, String label, {String text = ''}) {
      return Expanded(
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            customBorder: StadiumBorder(),
            onTap: () => _step(d),
            child: Ink(
              height: 38,
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: cInk.withValues(alpha: 0.16), width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: text.isEmpty ? 24 : 16, color: cInk),
                  if (text.isNotEmpty) ...[
                    SizedBox(width: 6),
                    Text(
                      text,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cInk),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      spacing: 6,
      children: [
        button(-1, KIcons.arrowLeft, ui('Предыдущая фраза')),
        button(0, KIcons.refresh, ui('Ещё раз'), text: ui('Ещё раз')),
        button(1, KIcons.arrowRight, ui('Следующая фраза')),
      ],
    );
  }

  Widget _current(Cue? cue) {
    final ru = cue != null && _showRu ? _ruFor(cue) : '';
    return Material(
      color: cAccent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 0), child: _controls()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 68),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_sr.isEmpty && widget.video.mine)
                    Text(
                      store.myVideo(videoId)?.status == SubsStatus.failed
                          ? ui('Не удалось создать субтитры. Попробуй ещё раз в «Моих роликах».')
                          : ui('Готовим субтитры — они появятся здесь, как только будут готовы.'),
                      style: TextStyle(fontSize: 14, height: 1.45, color: cInk.withValues(alpha: 0.72)),
                    ),
                  if (_subsLoading) Center(child: KapLoader(size: 32)),
                  if (cue != null && _showSr) PhraseWords(cue, onWord: (w) => _openWord(w, cue)),
                  if (ru.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(
                      ru,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: cInk.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Кнопка «Открыть в YouTube» в шапке, как у клипов — в TikTok.
  Widget _youtubeButton() {
    return IconButton(
      tooltip: ui('Открыть в YouTube'),
      icon: Icon(KIcons.youtube, size: 22, color: cMuted),
      onPressed: () {
        _yt.pauseVideo();
        launchUrl(Uri.parse('https://www.youtube.com/watch?v=$videoId'), mode: LaunchMode.externalApplication);
      },
    );
  }

  // Закреплены внизу: весь текст и сохранённые слова ролика открываются отдельными экранами.
  Widget _links() {
    return Row(
      spacing: 6,
      children: [
        Expanded(
          child: Pill(
            ui('Весь текст'),
            icon: KIcons.text,
            onTap: () => _push(
              SubPage(
                title: ui('Весь текст'),
                child: Transcript(sr: _sr, cur: _curN, ruFor: _showRu ? _ruFor : (_) => '', onSeek: _seek),
              ),
            ),
          ),
        ),
        Expanded(
          child: Pill(
            key: _wordsKey,
            ui('Мои слова'),
            badge: _words.length,
            icon: KIcons.wordsOn,
            onTap: () => _push(
              SubPage(
                title: ui('Мои слова'),
                child: WordList(videoId: videoId, onSeek: _seek),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

/// Экран поверх плеера: кнопка «Назад», заголовок и содержимое.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: ui('Назад'),
                        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Весь текст ролика; нажатие на фразу возвращает в плеер и включает её.
class Transcript extends StatefulWidget {
  const Transcript({
    super.key,
    required this.sr,
    required this.cur,
    required this.ruFor,
    required this.onSeek,
    this.popOnTap = true,
  });
  // В боковой колонке на десктопе экран не закрываем.
  final bool popOnTap;
  final List<Cue> sr;
  final ValueListenable<int> cur;
  final String Function(Cue) ruFor;
  final void Function(double) onSeek;

  @override
  State<Transcript> createState() => _TranscriptState();
}

class _TranscriptState extends State<Transcript> {
  final _rowKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    widget.cur.addListener(_onCur);
    _scrollToCur(Duration.zero);
  }

  @override
  void dispose() {
    widget.cur.removeListener(_onCur);
    super.dispose();
  }

  void _onCur() {
    setState(() {});
    _scrollToCur(Duration(milliseconds: 250));
  }

  void _scrollToCur(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[widget.cur.value]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.3, duration: duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sr = widget.sr, cur = widget.cur.value;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        children: [
          for (var i = 0; i < sr.length; i++)
            InkWell(
              key: _rowKeys.putIfAbsent(i, GlobalKey.new),
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (widget.popOnTap) Navigator.pop(context);
                widget.onSeek(sr[i].start);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: i == cur ? cCard : null, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          fmtTime(sr[i].start),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFaint),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.conv(sr[i].text),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: i == cur ? cText : cMuted,
                            ),
                          ),
                          if (widget.ruFor(sr[i]).isNotEmpty)
                            Text(widget.ruFor(sr[i]), style: TextStyle(fontSize: 13, height: 1.35, color: cMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Слова, сохранённые из этого ролика; нажатие возвращает в плеер к месту, где слово прозвучало.
class WordList extends StatelessWidget {
  const WordList({super.key, required this.videoId, required this.onSeek, this.popOnTap = true});
  final bool popOnTap;
  final String videoId;
  final void Function(double) onSeek;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.words.where((w) => w.video == videoId).toList().reversed.toList();
        if (list.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: Text(ui('Нажми на слово в субтитрах и сохрани его.'), style: TextStyle(fontSize: 14, color: cMuted)),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 4, 12, 12 + MediaQuery.paddingOf(context).bottom),
          itemCount: list.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: cLine),
          itemBuilder: (_, i) {
            final w = list[i];
            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (popOnTap) Navigator.pop(context);
                      onSeek(w.t);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.conv(w.key),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cText),
                          ),
                          if (w.tr.isNotEmpty)
                            Text(
                              w.tr,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cAccentText),
                            ),
                          Text(
                            store.conv(w.ctx),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: cFaint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: ui('Удалить {0}', [w.key]),
                  icon: Icon(Icons.close, size: 18, color: cMuted),
                  onPressed: () => store.remove(w.key),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
