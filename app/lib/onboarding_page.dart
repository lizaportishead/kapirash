import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_page.dart';
import 'store.dart';
import 'main.dart' show kAddVideoEnabled;
import 'theme.dart';
import 'l10n.dart';

class _Slide {
  const _Slide({
    required this.bg,
    required this.fg,
    required this.mark,
    required this.onMark,
    required this.title,
    required this.text,
    required this.art,
  });
  final Color bg, fg, mark, onMark;
  final String title, text;
  final Widget art;
}

List<_Slide> get _slides => [
  _Slide(
    bg: cAccent,
    fg: cInk,
    mark: cViolet,
    onMark: cOnViolet,
    title: ui('Учи *сербский* на\u00A0живом материале'),
    text: ui('Ролики, подкасты и книги — с сербскими субтитрами и переводом на русский.'),
    art: _ImageArt('assets/ill_onboarding.png'),
  ),
  _Slide(
    bg: cViolet,
    fg: cOnViolet,
    mark: cAccent,
    onMark: cInk,
    title: ui('Нажми на\u00A0*слово* — увидишь перевод.'),
    text: ui('Каждое слово в субтитрах и тексте книги можно открыть, не уходя с экрана.'),
    art: _WordArt(),
  ),
  _Slide(
    bg: cAccent,
    fg: cInk,
    mark: cViolet,
    onMark: cOnViolet,
    title: kAddVideoEnabled ? ui('Собирай *слова* отовсюду. *Добавляй* свои ролики.') : ui('Собирай *слова* из\u00A0роликов, подкастов и\u00A0книг.'),
    text: kAddVideoEnabled
        ? ui('Слова из роликов, подкастов и книг ждут в словарике, а любой ролик с YouTube можно добавить по ссылке.')
        : ui('Сохранённые слова ждут в словарике — повторяй их карточками и мини-тестами, когда удобно.'),
    art: _CardsArt(),
  ),
];

/// Короткий онбординг: три экрана в жёлтом и фиолетовом перед входом. Показываем один раз.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onDone});

  /// Если задан (веб на телефоне), вместо завершения онбординга зовём его: дальше экран входа.
  final VoidCallback? onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.onDone != null) return widget.onDone!();
    // Вход необязателен: зовём один раз поверх каталога, экран можно закрыть.
    if (store.user == null && store.canSignIn) openAuth(context, intro: true);
    store.finishOnboarding();
  }

  void _next() {
    if (_i == _slides.length - 1) {
      _finish();
    } else {
      _pages.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _slides[_i];
    final last = _i == _slides.length - 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: s.fg == cInk ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: s.bg,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: LangSwitch(color: s.fg),
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (i) => setState(() => _i = i),
                        children: [for (final s in _slides) _SlideView(s)],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _slides.length; i++)
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _i ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: s.fg.withValues(alpha: i == _i ? 1 : 0.3),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                          BigButton(
                            last ? ui('Начать') : ui('Дальше'),
                            bg: s.fg,
                            fg: s.fg == cInk ? cOnInk : cInk,
                            onTap: _next,
                          ),
                          // На последнем экране пропускать нечего, но место держим, чтобы кнопка не прыгала.
                          Visibility(
                            visible: !last,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                foregroundColor: s.fg,
                                textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              child: Text(ui('Пропустить')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Маленький переключатель языка «RU | EN» для экранов до входа.
class LangSwitch extends StatelessWidget {
  const LangSwitch({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (_, _) {
        Widget item(String code, String label) {
          final on = store.lang == code;
          return Semantics(
            button: true,
            selected: on,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => store.setLang(code),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    color: color.withValues(alpha: on ? 1 : 0.5),
                  ),
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [item('ru', 'RU'), Text('|', style: TextStyle(color: color.withValues(alpha: 0.3))), item('en', 'EN')],
        );
      },
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.s, {this.compact = false});
  final _Slide s;

  /// Для боковой панели на десктопе: заголовок мельче.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Headline(s.title, color: s.fg, mark: s.mark, onMark: s.onMark, maxSize: compact ? 38 : 60),
              SizedBox(height: 14),
              Text(
                s.text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4, color: s.fg),
              ),
            ],
          ),
        ),
        // Картинка декоративная: на низком экране ужимается, а не обрезает текст.
        Expanded(
          child: ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: FittedBox(fit: BoxFit.scaleDown, child: s.art),
            ),
          ),
        ),
      ],
    );
  }
}

/// Иллюстрация с прозрачным фоном.
class _ImageArt extends StatelessWidget {
  const _ImageArt(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(asset, height: 170);
}

/// Строка субтитров с подсвеченным словом и его переводом.
class _WordArt extends StatelessWidget {
  const _WordArt();

  @override
  Widget build(BuildContext context) {
    const line = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35, color: cInk);
    return SizedBox(
      width: 330,
      height: 250,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 24,
            child: Transform.rotate(
              angle: -0.04,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(color: cOnInk, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'notAleksa · 0:42',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6E707B)),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Obišao', style: line),
                        Text('sam', style: line),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text('sela', style: line),
                        ),
                        Text('sa', style: line),
                        Text('najsmešnijim', style: line),
                        Text('imenima', style: line),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      ui('Я объехал сёла с самыми смешными названиями'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: Color(0xFF5A3FE0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Sticker('B1', color: cInk, fg: cOnInk, angle: 0.2),
          ),
          Positioned(right: 18, bottom: 6, child: Sticker(ui('sela — сёла'), color: cAccent, angle: 0.12)),
          Positioned(
            left: 0,
            bottom: 22,
            child: Sticker(ui('перевод'), color: cInk, fg: cOnInk, angle: -0.22),
          ),
        ],
      ),
    );
  }
}

/// Стопка карточек со словами и кнопка «плюс».
class _CardsArt extends StatelessWidget {
  const _CardsArt();

  static const _cards = [
    (0.0, 0.0, -0.1, 'kapiraš', 'понимаешь'),
    (56.0, 94.0, 0.06, 'selo', 'село'),
    (14.0, 186.0, -0.03, 'ajde', 'давай'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 290,
      child: Stack(
        children: [
          for (final (left, top, angle, word, tr) in _cards)
            Positioned(
              left: left,
              top: top,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 240,
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 16),
                  decoration: BoxDecoration(
                    color: cOnInk,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cInk, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cInk),
                      ),
                      Text(
                        ui(tr),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5A3FE0)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            top: 20,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: cViolet, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, size: 38, color: cOnViolet),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 0,
            child: Sticker('youtu.be/…', color: cInk, fg: cOnInk, angle: -0.14),
          ),
        ],
      ),
    );
  }
}

/// Те же три слайда в рамке для широкого экрана: листаются сами, можно кликнуть по точкам.
class OnboardingShowcase extends StatefulWidget {
  const OnboardingShowcase({super.key});

  @override
  State<OnboardingShowcase> createState() => _OnboardingShowcaseState();
}

class _OnboardingShowcaseState extends State<OnboardingShowcase> {
  final _pages = PageController();
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 6), (_) => _go((_i + 1) % _slides.length));
  }

  void _go(int i) {
    if (_pages.hasClients) _pages.animateToPage(i, duration: Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _slides[_i];
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(36)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: Column(
            children: [
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
                  ),
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) {
                      setState(() => _i = i);
                      _restart();
                    },
                    children: [for (final s in _slides) _SlideView(s, compact: true)],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _go(i);
                        _restart();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: i == _i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: s.fg.withValues(alpha: i == _i ? 1 : 0.3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
