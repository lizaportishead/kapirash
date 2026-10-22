import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_page.dart';
import 'hero_video_io.dart' if (dart.library.js_interop) 'hero_video_web.dart';
import 'icons.dart';
import 'l10n.dart';
import 'store.dart';
import 'subs.dart';
import 'theme.dart';

const _bg = Color(0xFF0B0B10);
const _soft = Color(0xB3FFFFFF);

/// Лендинг для веба вместо онбординга: один тёмный экран с заголовком, кнопкой регистрации и телефоном с роликом.
/// Показываем, пока человек не вошёл и не нажал «Смотреть без авторизации».
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(vsync: this, duration: Duration(seconds: 40))..repeat();

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _drift.dispose();
    super.dispose();
  }

  // Зарегистрировался — лендинг больше не нужен.
  void _onStore() {
    if (store.user != null && !store.onboarded) store.finishOnboarding();
  }

  void _signUp() {
    if (store.canSignIn) {
      openAuth(context, intro: true);
    } else {
      store.finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final pad = EdgeInsets.symmetric(horizontal: wide ? 40 : 24);
    Widget constrained(Widget child) => Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1100), child: Padding(padding: pad, child: child)),
    );
    final hero = constrained(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _nav(),
          SizedBox(height: wide ? 40 : 24),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _text(wide)),
                    SizedBox(width: 24),
                    // Сдвинут вправо, за поля контейнера: тексту слева остаётся больше воздуха.
                    Transform.translate(offset: Offset(56, 0), child: LandingPhone(wide: wide)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_text(wide), SizedBox(height: 40), Center(child: LandingPhone(wide: wide))],
                ),
          SizedBox(height: 48),
        ],
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Хиро: тёмный фон с фиолетовым свечением снизу и плывущими буквами.
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 40),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.55, 1],
                              colors: [_bg, cViolet.withValues(alpha: 0.5)],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(child: ExcludeSemantics(child: _Letters(_drift))),
                      hero,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav() => SizedBox(
    height: 72,
    child: Row(
      children: [
        Text.rich(
          TextSpan(
            text: 'Kapiraš',
            children: [TextSpan(text: '?', style: TextStyle(color: cAccent))],
          ),
          style: TextStyle(fontSize: 22.5, fontWeight: FontWeight.w900, letterSpacing: -0.75, color: Colors.white),
        ),
        Spacer(),
        if (store.canSignIn)
          TextButton(
            onPressed: _signUp,
            style: TextButton.styleFrom(
              foregroundColor: _soft,
              textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(ui('Войти')),
          ),
      ],
    ),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: EdgeInsets.fromLTRB(10, 7, 13, 7),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    ),
  );

  Widget _text(bool wide) {
    final size = wide ? 56.0 : 38.0;
    TextStyle h(Color c) =>
        TextStyle(fontSize: size, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -size * 0.03, color: c);
    // Каждая часть заголовка строго в одну строку: если не влезает, шрифт чуть ужимается.
    Widget line(String text, Color c) => Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(text, style: h(c))),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [line(ui('Ленивый способ'), Colors.white), line(ui('учить сербский'), cAccent)],
          ),
        ),
        SizedBox(height: 24),
        Text(
          ui('Учи новые слова с помощью интересных роликов и подкастов'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.45, color: _soft),
        ),
        SizedBox(height: 20),
        // Все четыре плашки строго в одну строку: если не влезают, ужимаются целиком.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip(KIcons.catalogOn, ui('Видео')),
              SizedBox(width: 6),
              _chip(KIcons.clipsOn, ui('Шортсы')),
              SizedBox(width: 6),
              _chip(KIcons.storiesOn, ui('Книги')),
              SizedBox(width: 6),
              _chip(Icons.headphones_rounded, ui('Подкасты')),
            ],
          ),
        ),
        SizedBox(height: 28),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320),
          child: BigButton(ui('Начать'), onTap: _signUp, bg: cAccent, fg: cInk),
        ),
      ],
    );
  }
}

/// Телефон с кадром ролика и плавающими плашками вокруг.
class LandingPhone extends StatefulWidget {
  const LandingPhone({required this.wide});
  final bool wide;

  @override
  State<LandingPhone> createState() => _PhoneState();
}

const _heroId = '7684326403902360852';

/// Строка субтитров с подсвеченным словом и его переводом.
class _Line {
  const _Line(this.sr, this.tr, this.word, this.wordTr, this.note);
  final String sr, tr, word, wordTr, note;
}

class _PhoneState extends State<LandingPhone> {
  // Реальные субтитры ролика с блогером: сербский, перевод и словарь грузим из ассетов, время берём у видео.
  List<Cue> _sr = [], _tr = [];
  Map<String, dynamic> _dict = {};
  int _i = -1;
  // Реплика, чья карточка перевода сейчас на экране: остаётся, пока не тапнут следующее слово.
  int _cardIdx = -1;
  // Чётные реплики показываем справа, нечётные слева; старая плашка гаснет на своей стороне.
  int _rightIdx = -1, _leftIdx = -1;

  // После появления карточки палец тапает «Сохранить», и кнопка становится «Сохранено».
  bool _saveFinger = false, _saved = false;
  Timer? _fingerTimer, _saveTimer;

  // Через ~0.35 с после начала реплики «палец» тапает по слову, ещё через 0.35 с всплывает плашка с переводом.
  bool _finger = false, _tapped = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sr = parseSubs(await store.assetText('$_heroId.sr.vtt', en: '$_heroId.sr.vtt'));
      final tr = parseSubs(await store.assetText('$_heroId.ru.vtt', en: '$_heroId.en.vtt'));
      final dict = jsonDecode(await store.assetText('$_heroId.dict.json', en: '$_heroId.dict.en.json')) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _sr = sr;
        _tr = tr;
        _dict = dict;
      });
    } catch (_) {}
  }

  void _onTime(double time) {
    if (!mounted) return;
    final i = cueAt(_sr, time);
    // Между репликами ничего не сбрасываем: субтитры и карточка остаются до следующей реплики.
    final phase = i < 0 ? -1.0 : time - _sr[i].start;
    final finger = phase >= 0.5 && phase < 1.1, tapped = phase >= 0.9;
    final ni = i >= 0 ? i : _i;
    final card = tapped ? i : _cardIdx;
    if (ni != _i || finger != _finger || tapped != _tapped || card != _cardIdx) {
      if (card != _cardIdx) {
        _restartSave();
        if (card.isEven) {
          _rightIdx = card;
        } else {
          _leftIdx = card;
        }
      }
      setState(() {
        _i = ni;
        _finger = finger;
        _tapped = tapped;
        _cardIdx = card;
      });
    }
  }

  void _restartSave() {
    _fingerTimer?.cancel();
    _saveTimer?.cancel();
    _saved = false;
    _saveFinger = false;
    _fingerTimer = Timer(Duration(milliseconds: 600), () => mounted ? setState(() => _saveFinger = true) : null);
    _saveTimer = Timer(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _saveFinger = false;
          _saved = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _fingerTimer?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Самое длинное слово реплики [idx], которое есть в словаре.
  _Line? _lineAt(int idx) {
    if (idx < 0 || idx >= _sr.length) return null;
    final sr = _sr[idx].text;
    var best = '', bestTr = '', note = '';
    for (final w in sr.split(' ')) {
      final e = _dict[cleanWord(w).toLowerCase()];
      if (e is List && cleanWord(w).length > cleanWord(best).length) {
        best = w;
        bestTr = '${e.first}'.split(';').first.split(',').first;
        note = e.length > 1 ? '${e[1]}' : '';
      }
    }
    return _Line(sr, idx < _tr.length ? _tr[idx].text : '', best, bestTr, note);
  }

  _Line? get _line => _lineAt(_i);

  @override
  Widget build(BuildContext context) {
    final wide = widget.wide;
    return ExcludeSemantics(
      child: SizedBox(
        width: wide ? 520 : 380,
        height: 620,
        child: Stack(
          children: [
            Positioned(left: wide ? 122 : 52, top: 30, child: _screen()),
            // Плашки с переводом вылезают то справа, то слева от экрана (на узком — поверх его края).
            for (final side in const [true, false])
              Positioned(
                left: side ? null : 0,
                right: side ? 0 : null,
                top: wide ? (side ? 340 : 220) : (side ? 190 : 310),
                width: wide ? 165 : 150,
                child: IgnorePointer(
                  // Плашка остаётся, пока на её сторону не придёт следующая; старая медленно тускнеет,
                  // поэтому какое-то время на экране видны две сразу.
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 700),
                    opacity: (side ? _rightIdx : _leftIdx) < 0 ? 0 : ((side ? _rightIdx : _leftIdx) == _cardIdx ? 1 : 0.55),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 700),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: Offset(side ? 0.15 : -0.15, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(side ? _rightIdx : _leftIdx),
                        child: _wordCard(_lineAt(side ? _rightIdx : _leftIdx), active: _cardIdx == (side ? _rightIdx : _leftIdx)),
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

  Widget _wordCard(_Line? l, {bool active = true}) {
    if (l == null) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cleanWord(l.word).toLowerCase(),
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Colors.white),
          ),
          SizedBox(height: 2),
          Text(l.wordTr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFB5A6FF))),
          if (l.note.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              l.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, height: 1.3, color: Colors.white60),
            ),
          ],
          SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                height: 32,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: active && _saved ? cAccent : cViolet, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(active && _saved ? Icons.check_rounded : Icons.bookmark_add_rounded, size: 15, color: active && _saved ? cInk : cOnViolet),
                    SizedBox(width: 6),
                    Text(
                      active && _saved ? ui('Сохранено') : ui('Сохранить'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active && _saved ? cInk : cOnViolet),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: -18,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 150),
                  opacity: active && _saveFinger ? 1 : 0,
                  child: Icon(Icons.touch_app_rounded, size: 28, color: cInk, shadows: [Shadow(color: Colors.white, blurRadius: 6)]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _screen() {
    const line = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35, color: cInk);
    Widget action(IconData icon) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.white),
    );
    // Корпус, боковые кнопки и экран.
    return SizedBox(
      width: 276,
      height: 560,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -3, top: 110, child: _btn(28)),
          Positioned(left: -3, top: 160, child: _btn(52)),
          Positioned(right: -3, top: 140, child: _btn(72)),
          Container(
            decoration: BoxDecoration(
              color: cInk,
              border: Border.all(color: Colors.white24, width: 1.5),
              borderRadius: BorderRadius.circular(46),
              boxShadow: [
                BoxShadow(color: cViolet.withValues(alpha: 0.30), blurRadius: 80, spreadRadius: 4, offset: Offset(0, 24)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 24, offset: Offset(0, 12)),
              ],
            ),
            padding: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HeroVideo(src: 'hero2.mp4', onTime: _onTime),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                      ),
                    ),
                  ),
                  // Островок камеры и полоска прогресса.
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 78,
                        height: 22,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 42,
                    left: 14,
                    right: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: [
                          Container(height: 3, color: Colors.white38),
                          FractionallySizedBox(widthFactor: 0.4, child: Container(height: 3, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(right: 12, top: 190, child: Column(children: [action(KIcons.heart), SizedBox(height: 10), action(KIcons.words)])),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 18,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                      decoration: BoxDecoration(color: cOnInk, borderRadius: BorderRadius.circular(22)),
                      child: AnimatedSize(
                        duration: Duration(milliseconds: 250),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 250),
                          child: _line == null ? SizedBox(key: ValueKey(-1), width: double.infinity) : _subLine(_line!, line, ValueKey(_i)),
                        ),
                      ),
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

  Widget _subLine(_Line sub, TextStyle line, Key key) {
    final words = sub.sr.split(' ');
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final w in words)
              w == sub.word
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: _tapped ? cViolet : cAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(w, style: line.copyWith(color: _tapped ? cOnViolet : cInk)),
                        ),
                        Positioned(
                          right: -10,
                          bottom: -22,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: 150),
                            opacity: _finger ? 1 : 0,
                            child: Icon(Icons.touch_app_rounded, size: 34, color: cInk, shadows: [Shadow(color: Colors.white, blurRadius: 6)]),
                          ),
                        ),
                      ],
                    )
                  : Text(w, style: line),
          ],
        ),
        SizedBox(height: 5),
        Text(sub.tr, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF5A3FE0))),
      ],
    );
  }

  Widget _btn(double h) => Container(
    width: 3,
    height: h,
    decoration: BoxDecoration(color: Color(0xFF2B2B33), borderRadius: BorderRadius.circular(2)),
  );
}

/// Сербские буквы медленно плывут по фону.
class _Letters extends StatelessWidget {
  const _Letters(this.t);
  final Animation<double> t;

  static const _chars = 'čćšžđČĆŠŽĐABCDEGHJKLMNOPRSTUVZ';
  static final _items = () {
    final r = math.Random(7);
    return [
      for (var i = 0; i < 28; i++)
        (x: r.nextDouble(), y: r.nextDouble(), ch: _chars[r.nextInt(_chars.length)], size: 12 + r.nextDouble() * 12, speed: 0.4 + r.nextDouble() * 0.8),
    ];
  }();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, _) => LayoutBuilder(
        builder: (_, box) => Stack(
          children: [
            for (final it in _items)
              Positioned(
                left: it.x * box.maxWidth,
                // Плывут вверх и возвращаются снизу.
                top: ((it.y - t.value * it.speed * 2) % 1) * box.maxHeight,
                child: Text(
                  it.ch,
                  style: TextStyle(fontSize: it.size, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
