import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_page.dart';
import 'icons.dart';
import 'l10n.dart';
import 'store.dart';
import 'theme.dart';

/// Вторая версия лендинга: светлый, плакатный хиро с огромным заголовком, плоскими фигурками и телефоном поверх букв.
/// Открывается по адресу с `?landing=2`.
class LandingPage2 extends StatefulWidget {
  const LandingPage2({super.key});

  @override
  State<LandingPage2> createState() => _LandingPage2State();
}

class _LandingPage2State extends State<LandingPage2> {
  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
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
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 860;
    final w = math.min(size.width, 1280.0);
    // Размер букв заголовка подстраиваем под ширину, чтобы слово занимало почти весь экран.
    final fs = wide ? math.min(w * 0.30, 340.0) : size.width * 0.34;
    final heroH = wide ? 790.0 : 740.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cAccent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 1280),
                    child: SizedBox(
                      height: heroH,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          ..._decor(wide),
                          // Заголовок: две строки огромных букв, телефон встаёт поверх них.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: wide ? 96 : 84,
                            child: Semantics(
                              header: true,
                              child: Column(
                                children: [
                                  _word(ui('Ленивый способ'), fs * 0.62, cInk, width: size.width - (wide ? 120 : 32)),
                                  Transform.translate(
                                    offset: Offset(0, -fs * 0.10),
                                    child: _word(ui('учить сербский'), fs * 0.62, cViolet, width: size.width - (wide ? 120 : 32)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Под заголовком: подпись, плашки и кнопка по центру.
                          Positioned(
                            left: 24,
                            right: 24,
                            top: wide ? 470 : 330,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 560),
                                child: Column(
                                  children: [
                                    _tagline(),
                                    SizedBox(height: 20),
                                    _chips(),
                                    SizedBox(height: 28),
                                    SizedBox(width: 280, child: BigButton(ui('Начать'), onTap: _signUp)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(left: 0, right: 0, top: 0, child: _nav(wide)),
                        ],
                      ),
                    ),
                  ),
                ),
                _how(wide),
                _finale(wide),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Блок «Как это работает»: чередуем картинку и текст слева и справа.
  Widget _how(bool wide) {
    final steps = [
      (
        title: ui('Смотри и слушай'),
        text: ui(
          'Ролики, шортсы, подкасты и книги с субтитрами на сербском и переводом. Фразы подсвечиваются в такт речи.',
        ),
        art: _ArtWatch(),
        bg: cViolet,
      ),
      (
        title: ui('Нажимай на слова'),
        text: ui('Любое слово в субтитрах можно открыть, не уходя из ролика: перевод и пример появятся сразу.'),
        art: _ArtTap(),
        bg: cInk,
      ),
      (
        title: ui('Тренируй'),
        text: ui('Сохранённые слова ждут в словарике. Повторяй их карточками и мини-тестами, когда удобно.'),
        art: _ArtTrain(),
        bg: cAccent,
      ),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(wide ? 48 : 32)),
            padding: EdgeInsets.symmetric(vertical: wide ? 96 : 56, horizontal: wide ? 56 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Text(
                      ui('Как это работает'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: wide ? 56 : 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.05,
                        color: cInk,
                      ),
                    ),
                    SizedBox(height: wide ? 72 : 40),
                    for (var i = 0; i < steps.length; i++) ...[
                      if (i > 0) SizedBox(height: wide ? 80 : 48),
                      _step(wide, i, steps[i].title, steps[i].text, steps[i].art, steps[i].bg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Финал: центрированный призыв на лаймовом фоне с деревьями и бабочками.
  Widget _finale(bool wide) {
    final t = wide ? 1.0 : 0.6;
    return Container(
      width: double.infinity,
      height: wide ? 560 : 520,
      color: cAccent,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -40 * t,
            bottom: -30,
            child: _Trees(scale: t),
          ),
          Positioned(
            right: -40 * t,
            bottom: -30,
            child: Transform.flip(flipX: true, child: _Trees(scale: t)),
          ),
          Positioned(
            left: wide ? 300 : 20,
            top: wide ? 90 : 60,
            child: _Butterfly(size: 44 * t + 10),
          ),
          Positioned(
            right: wide ? 270 : 24,
            top: wide ? 190 : 150,
            child: _Butterfly(size: 40 * t + 10, flip: true),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ui('Начни учить сербский сегодня'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: wide ? 56 : 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.05,
                        color: cInk,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      ui('Слова, лайки и прогресс сохранятся в облаке.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: cInk.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(width: 280, child: BigButton(ui('Начать'), onTap: _signUp)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(bool wide, int i, String title, String text, Widget art, Color bg) {
    final picture = AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40)),
        child: art,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '0${i + 1}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cViolet),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: wide ? 44 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.05,
            color: cInk,
          ),
        ),
        SizedBox(height: 16),
        Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5, color: cInk.withValues(alpha: 0.75)),
        ),
      ],
    );
    if (!wide)
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [picture, SizedBox(height: 24), copy]);
    final left = i.isEven;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (left) Expanded(child: picture),
        SizedBox(width: 72),
        Expanded(
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: copy),
        ),
        if (!left) ...[SizedBox(width: 72), Expanded(child: picture)],
      ],
    );
  }

  Widget _word(String text, double size, Color color, {required double width}) => SizedBox(
    width: width,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -size * 0.04,
          color: color,
        ),
      ),
    ),
  );

  Widget _nav(bool wide) => Padding(
    padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20),
    child: SizedBox(
      height: 72,
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              text: brandName,
              children: [
                TextSpan(
                  text: '?',
                  style: TextStyle(color: cViolet),
                ),
              ],
            ),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.8, color: cInk),
          ),
          Spacer(),
          if (store.canSignIn)
            TextButton(
              onPressed: _signUp,
              style: TextButton.styleFrom(
                foregroundColor: cInk,
                textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: Text(ui('Войти')),
            ),
          SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _signUp,
              style: FilledButton.styleFrom(
                backgroundColor: cViolet,
                foregroundColor: cOnViolet,
                padding: EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: Text(ui('Начать')),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tagline() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        ui('Учи новые слова с помощью интересных роликов и подкастов'),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: cInk.withValues(alpha: 0.75)),
      ),
    ],
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: EdgeInsets.fromLTRB(10, 7, 14, 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: cInk, width: 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cInk),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cInk),
        ),
      ],
    ),
  );

  Widget _chips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      _chip(KIcons.catalogOn, ui('Видео')),
      _chip(KIcons.clipsOn, ui('Шортсы')),
      _chip(KIcons.storiesOn, ui('Книги')),
      _chip(Icons.headphones_rounded, ui('Подкасты')),
    ],
  );

  // Плоские фигурки как на референсе: солнце, облака, цветок-смайлик, искры.
  List<Widget> _decor(bool wide) => [
    Positioned(
      left: 0,
      right: 0,
      top: wide ? 60 : 90,
      child: Center(
        child: Container(
          width: wide ? 300 : 200,
          height: wide ? 300 : 200,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    ),
    Positioned(
      left: wide ? 70 : -30,
      top: wide ? 110 : 150,
      child: _Cloud(width: wide ? 200 : 120),
    ),
    Positioned(
      right: wide ? -30 : -40,
      top: wide ? 150 : 200,
      child: _Cloud(width: wide ? 280 : 150),
    ),
    Positioned(
      right: wide ? 230 : 20,
      top: wide ? 70 : 100,
      child: _Flower(size: wide ? 130 : 80),
    ),
    Positioned(
      left: wide ? 260 : 40,
      top: wide ? 330 : 360,
      child: _Sparkle(size: 34, color: cViolet),
    ),
    Positioned(
      right: wide ? 300 : 60,
      top: wide ? 560 : 640,
      child: _Sparkle(size: 44, color: cInk),
    ),
    Positioned(
      left: wide ? 110 : 20,
      top: wide ? 700 : 760,
      child: _Sparkle(size: 26, color: cViolet),
    ),
  ];
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.42;
    Widget c(double l, double b, double d) => Positioned(
      left: l * width,
      bottom: b * h,
      child: Container(
        width: d * width,
        height: d * width,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: h * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          c(0.14, 0.2, 0.3),
          c(0.38, 0.2, 0.42),
          c(0.64, 0.2, 0.26),
        ],
      ),
    );
  }
}

/// Фиолетовый цветок с мордочкой.
class _Flower extends StatelessWidget {
  const _Flower({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final petal = size * 0.42;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 8; i++)
            Transform.translate(
              offset: Offset(math.cos(i * math.pi / 4) * size * 0.3, math.sin(i * math.pi / 4) * size * 0.3),
              child: Container(
                width: petal,
                height: petal,
                decoration: BoxDecoration(color: cViolet, shape: BoxShape.circle),
              ),
            ),
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(color: cViolet, shape: BoxShape.circle),
          ),
          Positioned(
            top: size * 0.4,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: size * 0.06),
                        width: size * 0.06,
                        height: size * 0.06,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                  ],
                ),
                SizedBox(height: size * 0.03),
                Container(
                  width: size * 0.16,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(99)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SparklePainter(color));
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.width / 2, k = r * 0.18;
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r);
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// Волнистая толстая «дорожка» из референса: полукруги, торчащие из угла картинки.
Widget _wave(Color c, {double size = 150}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: c, width: size * 0.22),
  ),
);

Widget _pill(String text, {Color bg = Colors.white, Color fg = cInk, double size = 18}) => Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
  child: Text(
    text,
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: fg),
  ),
);

/// Ролик с субтитрами, наушники и звук.
class _ArtWatch extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, b) => Stack(
      children: [
        Positioned(right: -40, bottom: -50, child: _wave(cAccent, size: 200)),
        Positioned(
          left: b.maxWidth * 0.1,
          top: b.maxHeight * 0.14,
          right: b.maxWidth * 0.22,
          bottom: b.maxHeight * 0.2,
          child: Container(
            decoration: BoxDecoration(color: cInk, borderRadius: BorderRadius.circular(24)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: cAccent, shape: BoxShape.circle),
                  child: Icon(Icons.play_arrow_rounded, size: 40, color: cInk),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      'Ovo je najlepše selo',
                      style: TextStyle(fontWeight: FontWeight.w800, color: cInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: b.maxWidth * 0.08,
          top: b.maxHeight * 0.12,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: cAccent, shape: BoxShape.circle),
            child: Icon(Icons.headphones_rounded, size: 40, color: cInk),
          ),
        ),
        Positioned(left: 24, top: 22, child: _Sparkle(size: 30, color: cAccent)),
      ],
    ),
  );
}

/// Предложение с выделенным словом и карточкой перевода.
class _ArtTap extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, b) => Stack(
      children: [
        Positioned(left: -50, bottom: -60, child: _wave(cViolet, size: 200)),
        Positioned(
          left: b.maxWidth * 0.1,
          top: b.maxHeight * 0.16,
          child: Wrap(
            spacing: 8,
            children: [
              _pill('Ovo'),
              _pill('je'),
              _pill('selo', bg: cViolet, fg: cOnViolet),
            ],
          ),
        ),
        Positioned(
          right: b.maxWidth * 0.1,
          bottom: b.maxHeight * 0.16,
          child: Container(
            width: 190,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'selo',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: cInk),
                ),
                Text(
                  'село, деревня',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cInk),
                ),
                SizedBox(height: 12),
                Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: cViolet, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    ui('Сохранить'),
                    style: TextStyle(fontWeight: FontWeight.w800, color: cOnViolet),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: b.maxWidth * 0.34,
          top: b.maxHeight * 0.3,
          child: Icon(Icons.touch_app_rounded, size: 64, color: cAccent),
        ),
        Positioned(right: 28, top: 24, child: _Sparkle(size: 34, color: cAccent)),
      ],
    ),
  );
}

/// Карточки для повторения слов.
class _ArtTrain extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, b) => Stack(
      children: [
        Positioned(right: -50, top: -60, child: _wave(Colors.white, size: 200)),
        Positioned(
          left: b.maxWidth * 0.1,
          top: b.maxHeight * 0.14,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 190,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: cInk, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'selo',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  SizedBox(height: 6),
                  Text(
                    ui('Перевод?'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: b.maxWidth * 0.1,
          bottom: b.maxHeight * 0.14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _pill('река'),
              SizedBox(height: 8),
              _pill('село', bg: cViolet, fg: cOnViolet),
              SizedBox(height: 8),
              _pill('гора'),
            ],
          ),
        ),
        Positioned(
          left: b.maxWidth * 0.12,
          bottom: b.maxHeight * 0.12,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: cViolet, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 40, color: cOnViolet),
          ),
        ),
      ],
    ),
  );
}

/// Два дерева-кружка: тёмное и светлое, у каждого ствол и волны.
class _Trees extends StatelessWidget {
  const _Trees({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    Widget tree(double d, Color c, Color wave) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.waves_rounded, size: d * 0.35, color: wave),
        ),
        Container(width: d * 0.22, height: d * 0.45, color: cInk),
      ],
    );
    return SizedBox(
      width: 340 * scale,
      height: 400 * scale,
      child: Stack(
        children: [
          Positioned(left: 0, bottom: 0, child: tree(200 * scale, cInk, cViolet)),
          Positioned(left: 130 * scale, bottom: -50 * scale, child: tree(170 * scale, cViolet, cAccent)),
        ],
      ),
    );
  }
}

class _Butterfly extends StatelessWidget {
  const _Butterfly({required this.size, this.flip = false});
  final double size;
  final bool flip;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: flip ? 0.4 : -0.4,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final left in [true, false])
          Container(
            width: size * 0.5,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: cViolet,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(left ? size : size * 0.1),
                topRight: Radius.circular(left ? size * 0.1 : size),
                bottomLeft: Radius.circular(size * 0.3),
                bottomRight: Radius.circular(size * 0.3),
              ),
            ),
          ),
      ],
    ),
  );
}
