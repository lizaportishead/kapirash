import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'creator_page.dart';
import 'icons.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';

/// Открывает плеер поверх таббара.
void openVideo(BuildContext context, Video v, {double? startAt}) {
  store.markWatched(v.id);
  Navigator.of(context, rootNavigator: true).push(
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
  Map<String, dynamic> _dict = {};
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

  String get videoId => widget.video.id;
  // На странице ролика — только слова, сохранённые из него.
  List<SavedWord> get _words => store.words.where((w) => w.video == videoId).toList();
  bool get _cyr => store.cyr;
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
    if (!mounted || subs == null) return;
    setState(() {
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

  String _conv(String s) => store.conv(s);
  bool _isSaved(String w) => store.isSaved(toLat(cleanWord(w)).toLowerCase());

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
    final word = cleanWord(raw);
    if (word.isEmpty) return;
    _yt.pauseVideo();
    final lat = toLat(word), cyr = toCyr(lat), key = lat.toLowerCase();
    final entry = _dict[key] as List?;
    final tr = entry == null ? '' : entry[0] as String;
    final note = entry == null ? '' : entry[1] as String;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cBg,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
          // В горизонтальном режиме карточка может не поместиться по высоте.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _cyr ? cyr : lat,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.6,
                    color: cText,
                  ),
                ),
                SizedBox(height: 6),
                Text('${_cyr ? lat : cyr} · ${fmtTime(cue.start)}', style: TextStyle(fontSize: 15, color: cMuted)),
                SizedBox(height: 14),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(20)),
                  child: Text(_conv(cue.text), style: TextStyle(fontSize: 15, height: 1.45, color: cText)),
                ),
                SizedBox(height: 14),
                if (entry == null)
                  Text('Этого слова нет в словарике ролика.', style: TextStyle(fontSize: 14, color: cMuted))
                else ...[
                  Text(
                    tr,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25, color: cAccentText),
                  ),
                  if (note.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(note, style: TextStyle(fontSize: 14, height: 1.45, color: cMuted)),
                  ],
                ],
                SizedBox(height: 16),
                BigButton(
                  _isSaved(word) ? 'Уже в моих словах' : 'Добавить в мои слова',
                  onTap: () {
                    store.add(SavedWord(key: key, tr: tr, ctx: cue.text, t: cue.start, video: videoId));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: cText),
                              ),
                              SizedBox(height: 6),
                              _channel(),
                            ],
                          ),
                        ),
                      ),
                      LikeButton(widget.video.id),
                    ],
                  ),
                  player,
                  SizedBox(height: 10),
                  _controls(),
                  SizedBox(height: 10),
                  Expanded(child: SingleChildScrollView(child: _current(cue))),
                  SizedBox(height: 10),
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
              child: SizedBox(height: 70, child: Center(child: _strip(cue))),
            ),
          ),
        ],
      ),
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
          if (_showSr)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              children: [
                for (final w in cue.text.split(' '))
                  GestureDetector(
                    onTap: () => _openWord(w, cue),
                    child: Text(
                      _conv(w),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: cInk,
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                        decorationColor: _isSaved(w) ? cViolet : cInk.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
              ],
            ),
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
      tooltip: 'Назад',
      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: color ?? cText),
      onPressed: () => Navigator.pop(context),
    );
  }

  // Аватарка и имя автора; у чужих роликов ведут на страницу канала.
  Widget _channel() {
    final name = widget.video.channel;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CreatorAvatar(name, size: 22),
        SizedBox(width: 7),
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
      label: 'Канал $name',
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

  Widget _controls() {
    return Row(
      children: [
        Expanded(
          child: Pill('', icon: KIcons.arrowLeft, label: 'Предыдущая фраза', onTap: () => _step(-1)),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Pill('Ещё раз', icon: KIcons.refresh, onTap: () => _step(0)),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Pill('', icon: KIcons.arrowRight, label: 'Следующая фраза', onTap: () => _step(1)),
        ),
      ],
    );
  }

  Widget _current(Cue? cue) {
    final ru = cue != null && _showRu ? _ruFor(cue) : '';
    return Container(
      constraints: BoxConstraints(minHeight: 96),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sr.isEmpty && widget.video.mine)
            Text(
              store.myVideo(videoId)?.status == SubsStatus.failed
                  ? 'Не удалось создать субтитры. Попробуй ещё раз в «Моих роликах».'
                  : 'Готовим субтитры — они появятся здесь, как только будут готовы.',
              style: TextStyle(fontSize: 14, height: 1.45, color: cInk.withValues(alpha: 0.72)),
            ),
          if (cue != null && _showSr)
            Wrap(
              spacing: 7,
              children: [
                for (final w in cue.text.split(' '))
                  GestureDetector(
                    onTap: () => _openWord(w, cue),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _conv(w),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: cInk,
                          decoration: TextDecoration.underline,
                          decorationThickness: 2,
                          decorationColor: _isSaved(w) ? cViolet : cInk.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
    );
  }

  // Полный текст и слова ролика открываются отдельными экранами.
  Widget _links() {
    return Row(
      children: [
        Expanded(
          child: Pill(
            'Весь текст',
            onTap: () => _push(
              _SubPage(
                title: 'Весь текст',
                child: _Transcript(sr: _sr, cur: _curN, ruFor: _showRu ? _ruFor : (_) => '', onSeek: _seek),
              ),
            ),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Pill(
            'Мои слова${_words.isEmpty ? '' : ' · ${_words.length}'}',
            onTap: () => _push(
              _SubPage(
                title: 'Мои слова',
                child: _WordList(videoId: videoId, onSeek: _seek),
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
class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.child});
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
                        tooltip: 'Назад',
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
class _Transcript extends StatefulWidget {
  const _Transcript({required this.sr, required this.cur, required this.ruFor, required this.onSeek});
  final List<Cue> sr;
  final ValueListenable<int> cur;
  final String Function(Cue) ruFor;
  final void Function(double) onSeek;

  @override
  State<_Transcript> createState() => _TranscriptState();
}

class _TranscriptState extends State<_Transcript> {
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
                Navigator.pop(context);
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
class _WordList extends StatelessWidget {
  const _WordList({required this.videoId, required this.onSeek});
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
            child: Text('Нажми на слово в субтитрах и сохрани его.', style: TextStyle(fontSize: 14, color: cMuted)),
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
                      Navigator.pop(context);
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
                  tooltip: 'Удалить ${w.key}',
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
