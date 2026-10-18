import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_page.dart';
import 'l10n.dart';
import 'store.dart';
import 'theme.dart';

/// Лендинг для веба вместо онбординга: что это, как работает и кнопка регистрации.
/// Показываем, пока человек не вошёл и не нажал «Смотреть без авторизации».
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
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

  void _browse() => store.finishOnboarding();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: store.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _nav(),
                      SizedBox(height: wide ? 48 : 20),
                      _hero(wide),
                      SizedBox(height: wide ? 88 : 56),
                      _steps(wide),
                      SizedBox(height: wide ? 88 : 56),
                      _finalCta(wide),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
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
        Text(
          'Kapiraš',
          style: TextStyle(fontSize: 22.5, fontWeight: FontWeight.w900, letterSpacing: -0.75, color: cViolet),
        ),
        Spacer(),
        if (store.canSignIn)
          TextButton(
            onPressed: _signUp,
            style: TextButton.styleFrom(
              foregroundColor: cText,
              textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: Text(ui('Войти')),
          ),
      ],
    ),
  );

  Widget _hero(bool wide) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Headline(ui('Учи *сербский* по живым роликам'), color: cText, mark: cAccent),
        SizedBox(height: 20),
        Text(
          ui('Блогеры, путешествия, еда — с субтитрами и переводом на русский.'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.45, color: cMuted),
        ),
        SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 360),
            child: BigButton(ui('Зарегистрироваться'), onTap: _signUp),
          ),
        ),
        SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _browse,
            style: TextButton.styleFrom(
              foregroundColor: cMuted,
              textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(ui('Смотреть без авторизации')),
          ),
        ),
      ],
    );
    final art = ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(color: cAccent, borderRadius: BorderRadius.circular(40)),
        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _WordArt())),
      ),
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [text, SizedBox(height: 32), art],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 11, child: text),
        SizedBox(width: 56),
        Expanded(flex: 10, child: art),
      ],
    );
  }

  Widget _steps(bool wide) {
    final cards = [
      _StepCard(
        n: '1',
        title: ui('Смотри ролики'),
        text: ui('Подборка живых роликов с субтитрами на сербском и переводом.'),
        bg: cCard,
      ),
      _StepCard(
        n: '2',
        title: ui('Нажимай на слова'),
        text: ui('Каждое слово в субтитрах можно открыть, не уходя из ролика.'),
        bg: cViolet,
        fg: cOnViolet,
        mark: cAccent,
      ),
      _StepCard(
        n: '3',
        title: ui('Собирай словарик'),
        text: ui('Сохранённые слова ждут в словарике — повторяй их, когда удобно.'),
        bg: cCard,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ui('Как это работает'),
          style: TextStyle(fontSize: wide ? 32 : 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cText),
        ),
        SizedBox(height: 24),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) SizedBox(width: 16),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          )
        else
          for (var i = 0; i < cards.length; i++) ...[if (i > 0) SizedBox(height: 12), cards[i]],
      ],
    );
  }

  Widget _finalCta(bool wide) => Container(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: wide ? 56 : 36),
    decoration: BoxDecoration(color: cViolet, borderRadius: BorderRadius.circular(40)),
    child: Column(
      children: [
        Text(
          ui('Начни учить сербский сегодня'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 36 : 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
            color: cOnViolet,
          ),
        ),
        SizedBox(height: 12),
        Text(
          ui('Слова, лайки и прогресс сохранятся в облаке.'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cOnViolet.withValues(alpha: 0.85)),
        ),
        SizedBox(height: 28),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360),
          // Фон кнопки фиолетовый, как и блок, поэтому здесь она жёлтая.
          child: BigButton(ui('Зарегистрироваться'), onTap: _signUp, bg: cAccent, fg: cInk),
        ),
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.n,
    required this.title,
    required this.text,
    required this.bg,
    this.fg,
    this.mark,
  });
  final String n, title, text;
  final Color bg;
  final Color? fg, mark;

  @override
  Widget build(BuildContext context) {
    final fg = this.fg ?? cText;
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: mark ?? cAccent, shape: BoxShape.circle),
            child: Text(n, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cInk)),
          ),
          SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
          SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.45, color: fg.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// Строка субтитров с подсвеченным словом и его переводом.
class _WordArt extends StatelessWidget {
  const _WordArt();

  @override
  Widget build(BuildContext context) {
    const line = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35, color: cInk);
    return SizedBox(
      width: 360,
      height: 260,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 30,
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
          Positioned(right: 18, bottom: 10, child: Sticker(ui('sela — сёла'), color: cViolet, fg: cOnViolet, angle: 0.12)),
          Positioned(
            left: 0,
            bottom: 26,
            child: Sticker(ui('перевод'), color: cInk, fg: cOnInk, angle: -0.22),
          ),
        ],
      ),
    );
  }
}
