import 'dart:async';

import 'package:flutter/material.dart';

import 'collection_page.dart';
import 'icons.dart';
import 'kap_loader.dart';
import 'analytics.dart';
import 'deep_link.dart';
import 'l10n.dart';
import 'phrase.dart';
import 'pod_audio.dart';
import 'player_page.dart';
import 'quiz_page.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'video_card.dart';
import 'videos.dart';

/// Вкладка «Подкасты»: эпизоды с аудиоплеером, субтитрами и заданиями.
class PodcastsPage extends StatelessWidget {
  const PodcastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageTitle(
            ui('Подкасты'),
            actions: [
              IconButton(
                tooltip: ui('Избранное'),
                icon: Icon(KIcons.star, size: 24, color: cText),
                onPressed: () => _open(context, searchHint: null),
              ),
              IconButton(
                tooltip: ui('Поиск'),
                icon: Icon(KIcons.search, size: 24, color: cText),
                onPressed: () => _open(context, searchHint: ui('Поиск по подкастам')),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 720;
              if (!wide) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
                  children: [for (final p in podcasts) EpisodeTile(p)],
                );
              }
              return ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (var i = 0; i < podcasts.length; i += 2)
                    IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: EpisodeTile(podcasts[i], roomy: true)),
                        SizedBox(width: 20),
                        Expanded(
                          child: i + 1 < podcasts.length ? EpisodeTile(podcasts[i + 1], roomy: true) : SizedBox(),
                        ),
                      ],
                    ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, {required String? searchHint}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'CollectionPage'),
      builder: (_) => CollectionPage<Video>(
        title: ui('Избранные подкасты'),
        icon: KIcons.headphones,
        items: podcasts,
        likeId: (p) => p.id,
        text: (p) => '${p.title} ${p.channel}',
        tile: (p) => EpisodeTile(p),
        searchHint: searchHint,
        emptyLiked: ui('Ставь звёздочку подкастам, к которым хочешь вернуться. Они появятся тут.'),
      ),
    ),
  );
}

void openPodcast(BuildContext context, Video v, {double? startAt, bool autoplay = false}) {
  store.markWatched(v.id);
  trackEvent('podcast_opened', {'video_id': v.id});
  Navigator.of(context).push(
    MaterialPageRoute<void>(settings: urlSettings('PodcastPlayerPage', '/podcast/${v.id}'), builder: (_) => PodcastPlayerPage(video: v, startAt: startAt, autoplay: autoplay)),
  );
}

class EpisodeTile extends StatelessWidget {
  const EpisodeTile(this.video, {super.key, this.roomy = false});
  final Video video;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final done = store.isWatched(video.id);
    return Padding(
      padding: EdgeInsets.only(bottom: roomy ? 20 : 8),
      child: Material(
        color: cCard,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openPodcast(context, video),
          child: Padding(
            padding: EdgeInsets.all(roomy ? 18 : 12),
            child: Row(
              children: [
                _Cover(size: 64, channel: video.channel),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.channel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cViolet),
                      ),
                      SizedBox(height: 2),
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: cText),
                      ),
                      SizedBox(height: 4),
                      Text(
                        [video.duration, if (done) ui('Открывали')].join(' · '),
                        style: TextStyle(fontSize: 12, color: cMuted),
                      ),
                    ],
                  ),
                ),
                LikeButton(video.id),
                Semantics(
                  button: true,
                  label: ui('Играть'),
                  child: Material(
                    color: cViolet,
                    shape: CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => openPodcast(context, video, autoplay: true),
                      child: SizedBox(width: 44, height: 44, child: Icon(KIcons.play, size: 22, color: cOnViolet)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Обложки шоу лежат в сборке; у шоу без картинки остаётся фиолетовая плитка с наушниками.
const _covers = {
  'Naša posla': 'assets/podcast_nasa_posla.jpg',
  'SBS na srpskom': 'assets/podcast_sbs.jpg',
  'Dnevnik jedne mladosti': 'assets/podcast_dnevnik.jpg',
  'IT(H)S Talks': 'assets/podcast_iths.jpg',
};

class _Cover extends StatelessWidget {
  const _Cover({required this.size, required this.channel});
  final double size;
  final String channel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: cViolet, borderRadius: radius),
      child: Icon(KIcons.headphonesOn, size: size * 0.5, color: cOnViolet),
    );
    final asset = _covers[channel];
    if (asset == null) return placeholder;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}

class PodcastPlayerPage extends StatefulWidget {
  const PodcastPlayerPage({super.key, required this.video, this.startAt, this.autoplay = false});
  final Video video;
  final double? startAt;

  /// Открыли по кнопке плей в списке: звук запускается сразу.
  final bool autoplay;

  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage> {
  final _audio = PodAudio();
  final _subs = <StreamSubscription<Object?>>[];
  List<Cue> _sr = [], _ru = [];
  bool _subsLoading = true;
  Map<String, dynamic> _dict = {};
  List<QuizSection> _quiz = [];
  final _curN = ValueNotifier<int>(-1);
  int get _cur => _curN.value;
  final _wordsKey = GlobalKey();

  final _word = ValueNotifier<(String, Cue, Rect)?>(null);
  double _pos = 0, _total = 0;
  double? _drag;
  double _savedPos = -1;
  bool _playing = false, _started = false;
  final _rate = ValueNotifier<double>(1);

  String get id => widget.video.id;

  @override
  void initState() {
    super.initState();
    _rate.addListener(_applyRate);
    _subs.addAll([
      _audio.onPosition.listen((d) => _onTime(d.inMilliseconds / 1000)),
      _audio.onDuration.listen((d) => setState(() => _total = d.inMilliseconds / 1000)),
      _audio.onPlaying.listen((p) => setState(() => _playing = p)),
      _audio.onComplete.listen((_) {
        store.setPosition(id, null);
        store.setProgress(id, 1);
        setState(() => _playing = false);
      }),
    ]);
    _open();
    _load();
    loadQuiz(id).then((q) {
      if (mounted && q.isNotEmpty) setState(() => _quiz = q);
    });
  }

  Future<void> _open() async {
    final from = widget.startAt ?? store.positionOf(id) ?? 0;
    try {
      await _audio.setSource(widget.video.audio);
      if (from > 0) await _audio.seek(Duration(milliseconds: (from * 1000).round()));
      if (mounted) setState(() => _pos = from);
      if (widget.autoplay && mounted) {
        _started = true;
        await _audio.resume();
      }
    } catch (_) {}
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
    _rate.removeListener(_applyRate);
    _rate.dispose();
    _savePos(leaving: true);
    for (final s in _subs) {
      s.cancel();
    }
    _audio.dispose();
    _curN.dispose();
    _word.dispose();
    super.dispose();
  }

  void _savePos({bool leaving = false}) {
    if (!_started) return;
    final done = _total > 0 && _pos > _total - 5;
    store.setPosition(id, done ? null : _pos);
    if (done || _total > 0) store.setProgress(id, done ? 1 : _pos / _total, notify: leaving);
    _savedPos = _pos;
  }

  void _onTime(double t) {
    if (!mounted) return;
    _pos = t;
    if ((t - _savedPos).abs() >= 5) _savePos();
    var i = cueAt(_sr, t);
    if (i < 0) {
      for (var k = _sr.length - 1; k >= 0; k--) {
        if (_sr[k].start <= t) {
          i = k;
          break;
        }
      }
    }
    setState(() {
      if (i >= 0) _curN.value = i;
    });
  }

  Future<void> _toggle() async {
    if (_playing) return _audio.pause();
    final first = !_started;
    _started = true;
    // resume() right after setSourceUrl does nothing on web until the source is buffered; play() starts it at once.
    if (first) {
      await _audio.play(widget.video.audio, Duration(milliseconds: (_pos * 1000).round()));
    } else {
      await _audio.resume();
    }
  }

  Future<void> _seek(double t) async {
    t = t.clamp(0, _total > 0 ? _total : t).toDouble();
    _started = true;
    await _audio.seek(Duration(milliseconds: (t * 1000).round()));
    _onTime(t);
    await _audio.resume();
  }

  void _step(int d) {
    if (_sr.isEmpty) return;
    final i = ((_cur < 0 ? 0 : _cur) + d).clamp(0, _sr.length - 1);
    _seek(_sr[i].start);
  }

  void _applyRate() => _audio.setRate(_rate.value);

  String _ruFor(Cue c) {
    final j = cueAt(_ru, (c.start + c.end) / 2);
    return j >= 0 ? _ru[j].text : '';
  }

  void _openWord(String raw, Cue cue, Rect at) {
    if (cleanWord(raw).isEmpty) return;
    _audio.pause();
    if (MediaQuery.sizeOf(context).width >= 960) {
      final w = _word.value;
      // Повторное нажатие на то же слово закрывает карточку.
      _word.value = w != null && w.$1 == raw && w.$2.start == cue.start ? null : (raw, cue, at);
      return;
    }
    showWord(context, raw: raw, cue: cue, dict: _dict, videoId: id, flyTo: _wordsKey);
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(settings: RouteSettings(name: 'SubPage'), builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final cue = _cur >= 0 && _cur < _sr.length ? _sr[_cur] : null;
    if (MediaQuery.sizeOf(context).width >= 960) return _desktop(cue);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: ui('Назад'),
                        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Spacer(),
                      SettingsButton(title: ui('Настройки подкаста'), rate: _rate),
                      LikeButton(id),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _Cover(size: 72, channel: widget.video.channel),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.video.channel,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cViolet),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      widget.video.title,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: cText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14),
                          _transport(),
                          SizedBox(height: 10),
                          _current(cue),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _openText,
                              icon: Icon(KIcons.text, size: 18, color: cMuted),
                              label: Text(
                                ui('Весь текст'),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cMuted),
                              ),
                            ),
                          ),
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

  // Десктоп: шапка на всю ширину; слева обложка рядом с плеером и фраза под ними, справа — текст, слова и задания.
  Widget _desktop(Cue? cue) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: ui('Назад'),
                    icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Spacer(),
                  SettingsButton(title: ui('Настройки подкаста'), rate: _rate),
                  LikeButton(id),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, c) => SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: c.maxHeight),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 16,
                                children: [
                                  Container(
                                    padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
                                    decoration: BoxDecoration(
                                      color: cBg,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 16,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            _Cover(size: 72, channel: widget.video.channel),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    widget.video.channel,
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cViolet),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    widget.video.title,
                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: cText),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        _transport(),
                                      ],
                                    ),
                                  ),
                                  _current(cue),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(flex: 2, child: _sidePanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidePanel() {
    return VideoSidePanel(
      videoId: id,
      sr: _sr,
      cur: _curN,
      ruFor: _ruFor,
      onSeek: _seek,
      dict: _dict,
      subsLoading: _subsLoading,
      quiz: _quiz,
      word: _word,
      flyTo: _wordsKey,
      onPause: _audio.pause,
    );
  }

  Widget _transport() {
    final max = _total > 0 ? _total : 1.0;
    final value = (_drag ?? _pos).clamp(0, max).toDouble();
    Widget round(IconData icon, String label, VoidCallback onTap, {double size = 44, bool main = false}) => Semantics(
      button: true,
      label: label,
      child: Material(
        color: main ? cViolet : Colors.transparent,
        shape: CircleBorder(side: main ? BorderSide.none : BorderSide(color: cInk.withValues(alpha: 0.16), width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: main ? cOnViolet : cInk)),
        ),
      ),
    );
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: cViolet,
            inactiveTrackColor: cLine,
            thumbColor: cViolet,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value,
            max: max,
            onChanged: _total > 0 ? (v) => setState(() => _drag = v) : null,
            onChangeEnd: (v) {
              _drag = null;
              _seek(v);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(fmtTime(value), style: TextStyle(fontSize: 12, color: cMuted)),
              Spacer(),
              Text(_total > 0 ? fmtTime(_total) : widget.video.duration, style: TextStyle(fontSize: 12, color: cMuted)),
            ],
          ),
        ),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            SizedBox(width: 56),
            round(KIcons.back15, ui('Назад на 15 секунд'), () => _seek(_pos - 15)),
            round(_playing ? KIcons.pause : KIcons.play, _playing ? ui('Пауза') : ui('Играть'), _toggle, size: 64, main: true),
            round(KIcons.forward15, ui('Вперёд на 15 секунд'), () => _seek(_pos + 15)),
            SizedBox(width: 56),
          ],
        ),
      ],
    );
  }

  Widget _controls() {
    Widget button(int d, IconData icon, String label, {String text = ''}) => Expanded(
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
                  Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cInk)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
    final ru = cue != null ? _ruFor(cue) : '';
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
                  if (_subsLoading) Center(child: KapLoader(size: 32)),
                  if (cue != null) PhraseWords(cue, onWord: (w, at) => _openWord(w, cue, at)),
                  if (ru.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(
                      ru,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: cInk.withValues(alpha: 0.72)),
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

  void _openText() {
    _push(
      SubPage(
        title: ui('Весь текст'),
        child: Transcript(sr: _sr, cur: _curN, ruFor: _ruFor, onSeek: _seek),
      ),
    );
  }

  Widget _links() {
    final words = store.words.where((w) => w.video == id).length;
    return Row(
      spacing: 6,
      children: [
        if (_quiz.isNotEmpty)
          Expanded(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => Pill(
                ui('Задания'),
                badge: _quiz.where((s) => store.quizResult(id, s.title) == null).length,
                icon: KIcons.tasks,
                onTap: () => _push(SubPage(title: ui('Задания'), child: QuizList(videoId: id, sections: _quiz))),
              ),
            ),
          ),
        Expanded(
          child: Pill(
            key: _wordsKey,
            ui('Слова'),
            badge: words,
            icon: KIcons.wordsOn,
            onTap: () => _push(SubPage(title: ui('Словарь'), child: WordList(videoId: id, onSeek: _seek))),
          ),
        ),
      ],
    );
  }
}
