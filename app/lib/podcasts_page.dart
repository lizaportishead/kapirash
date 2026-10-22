import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'icons.dart';
import 'kap_loader.dart';
import 'l10n.dart';
import 'phrase.dart';
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
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Semantics(
              header: true,
              child: Text(
                ui('Подкасты'),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: cText),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              ui('Слушай и читай: фразы подсвечиваются в такт речи, любое слово можно нажать.'),
              style: TextStyle(fontSize: 14, height: 1.4, color: cMuted),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 16),
              children: [for (final p in podcasts) _EpisodeTile(p)],
            ),
          ),
        ],
      ),
    );
  }
}

void openPodcast(BuildContext context, Video v, {double? startAt, bool autoplay = false}) {
  store.markWatched(v.id);
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PodcastPlayerPage(video: v, startAt: startAt, autoplay: autoplay)),
  );
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile(this.video);
  final Video video;

  @override
  Widget build(BuildContext context) {
    final done = store.isWatched(video.id);
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Material(
        color: cCard,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openPodcast(context, video),
          child: Padding(
            padding: EdgeInsets.all(12),
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
                SizedBox(width: 8),
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
const _covers = {'Naša posla': 'assets/podcast_nasa_posla.jpg', 'SBS na srpskom': 'assets/podcast_sbs.jpg'};

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
  final _audio = AudioPlayer();
  final _subs = <StreamSubscription<Object?>>[];
  List<Cue> _sr = [], _ru = [];
  bool _subsLoading = true;
  Map<String, dynamic> _dict = {};
  List<QuizSection> _quiz = [];
  final _curN = ValueNotifier<int>(-1);
  int get _cur => _curN.value;
  final _wordsKey = GlobalKey();

  double _pos = 0, _total = 0;
  double? _drag;
  double _savedPos = -1;
  bool _playing = false, _started = false;
  double _rate = 1;

  String get id => widget.video.id;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _audio.onPositionChanged.listen((d) => _onTime(d.inMilliseconds / 1000)),
      _audio.onDurationChanged.listen((d) => setState(() => _total = d.inMilliseconds / 1000)),
      _audio.onPlayerStateChanged.listen((s) => setState(() => _playing = s == PlayerState.playing)),
      _audio.onPlayerComplete.listen((_) {
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
      await _audio.setSourceUrl(widget.video.audio);
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
    _savePos(leaving: true);
    for (final s in _subs) {
      s.cancel();
    }
    _audio.dispose();
    _curN.dispose();
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
    _started = true;
    await _audio.resume();
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

  Future<void> _setRate() async {
    _rate = _rate == 1 ? 0.8 : (_rate == 0.8 ? 0.6 : 1);
    await _audio.setPlaybackRate(_rate);
    setState(() {});
  }

  String _ruFor(Cue c) {
    final j = cueAt(_ru, (c.start + c.end) / 2);
    return j >= 0 ? _ru[j].text : '';
  }

  void _openWord(String raw, Cue cue) {
    if (cleanWord(raw).isEmpty) return;
    _audio.pause();
    showWord(context, raw: raw, cue: cue, dict: _dict, videoId: id, flyTo: _wordsKey);
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final cue = _cur >= 0 && _cur < _sr.length ? _sr[_cur] : null;
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
                          if (_quiz.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 28, 4, 8),
                              child: Text(
                                ui('Послушай подкаст и выполни задания'),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25, color: cText),
                              ),
                            ),
                            QuizList(videoId: id, sections: _quiz, inline: true),
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
            SizedBox(
              width: 56,
              child: TextButton(
                onPressed: _setRate,
                child: Text(
                  _rate == 1 ? '1×' : '$_rate×',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cInk),
                ),
              ),
            ),
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
                  if (cue != null) PhraseWords(cue, onWord: (w) => _openWord(w, cue)),
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

  Widget _links() {
    final words = store.words.where((w) => w.video == id).length;
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
                child: Transcript(sr: _sr, cur: _curN, ruFor: _ruFor, onSeek: _seek),
              ),
            ),
          ),
        ),
        Expanded(
          child: Pill(
            key: _wordsKey,
            ui('Словарь'),
            badge: words,
            icon: KIcons.wordsOn,
            onTap: () => _push(SubPage(title: ui('Словарь'), child: WordList(videoId: id, onSeek: _seek))),
          ),
        ),
      ],
    );
  }
}
