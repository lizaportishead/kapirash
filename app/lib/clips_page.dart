import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'icons.dart';
import 'liked_page.dart';
import 'phrase.dart';
import 'player_page.dart';
import 'search_page.dart';
import 'store.dart';
import 'subs.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'tiktok_player.dart';
import 'video_card.dart';
import 'videos.dart';
import 'l10n.dart';

/// Открывает клип поверх таббара; свайпом вверх и вниз листаются соседние — из [among], а без него все клипы.
void openClip(BuildContext context, Video v, {double? startAt, List<Video>? among}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ClipViewer(video: v, startAt: startAt, among: among),
    ),
  );
}

/// Обложка клипа: из сборки, а у клипов, появившихся после неё, — из облака (`<id>.jpg` рядом с субтитрами).
class ClipCover extends StatelessWidget {
  const ClipCover(this.v, {super.key});
  final Video v;

  @override
  Widget build(BuildContext context) {
    if (v.mock) {
      return Image.network(
        'https://i.ytimg.com/vi/${v.id.substring(5)}/mqdefault.jpg',
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => ColoredBox(color: cInk),
      );
    }
    return Image.asset(
      'assets/${v.id}.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.network(
        '$supabaseUrl/storage/v1/object/public/subs/${v.id}.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(color: cInk),
      ),
    );
  }
}

/// Сетка вертикальных обложек клипов.
const clipGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 240,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: 9 / 16,
);

/// Все короткие ролики на отдельном экране.
void openClips(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(body: SafeArea(bottom: false, child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1200), child: ClipsPage()))))));
}

/// Экран «Короткие ролики»: вертикальные ролики из TikTok.
class ClipsPage extends StatefulWidget {
  const ClipsPage({super.key});

  @override
  State<ClipsPage> createState() => _ClipsPageState();
}

class _ClipsPageState extends State<ClipsPage> {
  String? _topic;

  // Клипы могут обновиться из облака, пока экран открыт; метки на обложках тоже меняются.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: store, builder: (context, _) => _page());

  Widget _page() {
    final topics = {
      for (final v in clips)
        if (v.topic.isNotEmpty) v.topic,
    }.toList();
    final list = topics.contains(_topic) ? clips.where((v) => v.topic == _topic).toList() : clips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12),
            child: IconButton(
              tooltip: ui('Назад'),
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        PageTitle(
          ui('Шортсы'),
          actions: [
            IconButton(
              tooltip: ui('Любимое'),
              icon: Icon(KIcons.heart, size: 24, color: cText),
              onPressed: () => openLiked(context),
            ),
            IconButton(
              tooltip: ui('Поиск'),
              icon: Icon(KIcons.search, size: 24, color: cText),
              onPressed: () => openSearch(context, clips: true),
            ),
          ],
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            children: [
              Pill(ui('Все'), on: !topics.contains(_topic), onTap: () => setState(() => _topic = null)),
              for (final t in topics) ...[
                SizedBox(width: 6),
                Pill(topicLabel(t), on: _topic == t, onTap: () => setState(() => _topic = _topic == t ? null : t)),
              ],
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
            gridDelegate: clipGrid,
            itemCount: list.length,
            // Из выбранной темы листаются только её клипы.
            itemBuilder: (_, i) => ClipTile(list[i], among: list),
          ),
        ),
      ],
    );
  }
}

/// Плитка клипа в сетке; [among] — клипы, которые листаются свайпом после открытия.
class ClipTile extends StatelessWidget {
  const ClipTile(this.v, {super.key, required this.among});
  final Video v;
  final List<Video> among;

  @override
  Widget build(BuildContext context) {
    final words = store.wordCount(v.id);
    return Semantics(
      button: true,
      label: '${v.title}, ${v.channel}',
      child: Material(
        color: cInk,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openClip(context, v, among: among),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipCover(v),
              // Затемнение снизу, чтобы подпись читалась на любой обложке.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 1],
                    colors: [cInk.withValues(alpha: 0), cInk.withValues(alpha: 0.85)],
                  ),
                ),
              ),
              if (words > 0)
                Positioned(
                  left: 8,
                  top: 8,
                  child: VideoTag('$words ${plural(words, 'слово', 'слова', 'слов')}', accent: true),
                ),
              if (v.duration.isNotEmpty) Positioned(right: 8, top: 8, child: VideoTag(v.duration)),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.25, color: cOnInk),
                      ),
                      SizedBox(height: 3),
                      Text(
                        v.channel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: cOnInk.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Просмотр клипов: строка с названием и кнопками, вертикальное видео, под ним фраза с переводом.
class ClipViewer extends StatefulWidget {
  const ClipViewer({super.key, required this.video, this.startAt, this.among});
  final Video video;
  final double? startAt;
  final List<Video>? among;

  @override
  State<ClipViewer> createState() => _ClipViewerState();
}

class _ClipViewerState extends State<ClipViewer> {
  // Список фиксируем на входе: каталог может обновиться из облака, пока листаем.
  late final List<Video> _list = () {
    final all = widget.among ?? clips;
    return all.any((c) => c.id == widget.video.id) ? [...all] : [widget.video];
  }();
  late int _page = _list.indexWhere((c) => c.id == widget.video.id);
  late final _pages = PageController(initialPage: _page);

  @override
  void initState() {
    super.initState();
    store.markWatched(widget.video.id);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pages,
        scrollDirection: Axis.vertical,
        itemCount: _list.length,
        onPageChanged: (i) {
          store.markWatched(_list[i].id);
          setState(() => _page = i);
        },
        // Плеер живёт только у клипа, который сейчас на экране.
        itemBuilder: (_, i) => _ClipPage(
          video: _list[i],
          active: i == _page,
          startAt: _list[i].id == widget.video.id ? widget.startAt : null,
        ),
      ),
    );
  }
}

class _ClipPage extends StatefulWidget {
  const _ClipPage({required this.video, required this.active, this.startAt});
  final Video video;
  final bool active;
  final double? startAt;

  @override
  State<_ClipPage> createState() => _ClipPageState();
}

class _ClipPageState extends State<_ClipPage> {
  var _tt = TikTokController();
  List<Cue> _sr = [], _ru = [];
  Map<String, dynamic> _dict = {};
  final _curN = ValueNotifier<int>(-1);
  int get _cur => _curN.value;
  // Место, с которого просили открыть клип; перематываем туда один раз, когда плеер заиграет.
  late double? _startAt = widget.startAt;
  // Поверх клипа открыт экран с текстом или словами: плеер на это время убран, чтобы не играл за ним.
  bool _covered = false;

  String get videoId => widget.video.id;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _listen();
    _load();
  }

  void _listen() {
    _tt.time.addListener(_onTime);
    _tt.playing.addListener(_onPlaying);
  }

  @override
  void didUpdateWidget(_ClipPage old) {
    super.didUpdateWidget(old);
    // Клип ушёл с экрана — его плеер убран, и в следующий раз он начнёт сначала.
    if (old.active && !widget.active) {
      _resetPlayer();
      _curN.value = _sr.isEmpty ? -1 : 0;
    }
  }

  void _resetPlayer() {
    _tt.dispose();
    _tt = TikTokController();
    _listen();
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _tt.dispose();
    _curN.dispose();
    super.dispose();
  }

  void _onStore() => setState(() {});

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

  void _onPlaying() {
    final t = _startAt;
    if (_tt.playing.value && t != null) {
      _startAt = null;
      _tt.seek(t);
    }
    setState(() {});
  }

  void _onTime() {
    // Между фразами остаётся последняя прозвучавшая.
    final i = _sr.lastIndexWhere((c) => c.start <= _tt.time.value);
    if (i >= 0 && i != _cur) setState(() => _curN.value = i);
  }

  void _seek(double t) => _tt.seek(t < 0.15 ? 0 : t - 0.15);

  void _step(int d) {
    if (_sr.isEmpty) return;
    _seek(_sr[((_cur < 0 ? 0 : _cur) + d).clamp(0, _sr.length - 1)].start);
  }

  String _ruFor(Cue c) {
    final j = cueAt(_ru, (c.start + c.end) / 2);
    return j >= 0 ? _ru[j].text : '';
  }

  void _openWord(String raw, Cue cue) {
    if (cleanWord(raw).isEmpty) return;
    _tt.pause();
    showWord(context, raw: raw, cue: cue, dict: _dict, videoId: videoId);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = 12 + MediaQuery.paddingOf(context).bottom;
    // Горизонтальный телефон: видео слева во всю высоту, фраза и кнопки — справа от него.
    if (size.width > size.height) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 12, bottom),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _back(),
              _video(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(back: false),
                    // Фраза целиком, без прокрутки: если не помещается, чуть уменьшается.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, c) => Align(
                          alignment: Alignment.topCenter,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(width: c.maxWidth, child: _phrase()),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    _controls(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: _header()),
                Expanded(child: Center(child: _video())),
                SizedBox(height: 10),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: _controls()),
                SizedBox(height: 10),
                // Минимальная высота, чтобы видео не прыгало на коротких фразах; длинная фраза
                // показывается целиком, без прокрутки, и просто чуть сжимает видео.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: ConstrainedBox(constraints: BoxConstraints(minHeight: 112), child: _phrase()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _back() {
    return IconButton(
      tooltip: ui('Назад'),
      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
      onPressed: () => Navigator.pop(context),
    );
  }

  // Одна строка: назад, название и кнопки справа; текст и слова клипа спрятаны в меню.
  Widget _header({bool back = true}) {
    final v = widget.video;
    final words = store.wordCount(videoId);
    return Row(
      children: [
        if (back) _back(),
        Expanded(
          child: Text(
            v.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText),
          ),
        ),
        IconButton(
          tooltip: ui('Открыть в TikTok'),
          icon: Icon(KIcons.tiktok, size: 22, color: cMuted),
          onPressed: () {
            _tt.pause();
            launchUrl(Uri.parse(v.tiktokUrl), mode: LaunchMode.externalApplication);
          },
        ),
        LikeButton(v.id),
        PopupMenuButton<int>(
          tooltip: ui('Ещё'),
          icon: Icon(Icons.more_vert_rounded, size: 22, color: cMuted),
          color: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (i) => _push(
            (onSeek) => i == 0
                ? SubPage(
                    title: ui('Весь текст'),
                    child: Transcript(sr: _sr, cur: _curN, ruFor: _ruFor, onSeek: onSeek),
                  )
                : SubPage(
                    title: ui('Мои слова'),
                    child: WordList(videoId: videoId, onSeek: onSeek),
                  ),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(value: 0, child: Text(ui('Весь текст'))),
            PopupMenuItem(value: 1, child: Text('${ui('Мои слова')}${words == 0 ? '' : ' · $words'}')),
          ],
        ),
      ],
    );
  }

  // Полный текст и слова клипа открываются отдельными экранами. Плеер на это время убираем,
  // а по возвращении клип продолжается с того же места или с выбранной там фразы.
  Future<void> _push(Widget Function(void Function(double) onSeek) page) async {
    var at = _tt.time.value;
    _resetPlayer();
    setState(() => _covered = true);
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page((t) => at = t < 0.15 ? 0 : t - 0.15)));
    if (!mounted) return;
    setState(() {
      _covered = false;
      _startAt = at;
    });
  }

  Widget _video() {
    final playing = _tt.playing.value;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipCover(widget.video),
            if (widget.active && !_covered && !widget.video.mock)
              TikTokPlayer(key: ObjectKey(_tt), id: videoId, controller: _tt),
            // Своих кнопок у плеера нет: нажатие по видео ставит его на паузу и снимает с неё.
            Semantics(
              button: true,
              label: playing ? ui('Пауза') : ui('Смотреть'),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tt.toggle,
                child: AnimatedOpacity(
                  opacity: playing ? 0 : 1,
                  duration: Duration(milliseconds: 150),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: cInk.withValues(alpha: 0.55), shape: BoxShape.circle),
                      child: Icon(Icons.play_arrow_rounded, size: 40, color: cOnInk),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Row(
      children: [
        Expanded(
          child: Pill('', icon: KIcons.arrowLeft, label: ui('Предыдущая фраза'), onTap: () => _step(-1)),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Pill(ui('Ещё раз'), icon: KIcons.refresh, onTap: () => _step(0)),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Pill('', icon: KIcons.arrowRight, label: ui('Следующая фраза'), onTap: () => _step(1)),
        ),
      ],
    );
  }

  Widget _phrase() {
    final cue = _cur >= 0 && _cur < _sr.length ? _sr[_cur] : null;
    final ru = cue == null ? '' : _ruFor(cue);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(20)),
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cue != null) PhraseWords(cue, onWord: (w) => _openWord(w, cue), size: 17, pad: 2),
          if (ru.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              ru,
              style: TextStyle(
                fontSize: 13,
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
}
