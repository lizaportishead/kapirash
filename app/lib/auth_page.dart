import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'onboarding_page.dart' show OnboardingShowcase;
import 'store.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'l10n.dart';

const _kLastEmail = 'last_email';
final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Открывает вход поверх таббара. [intro] — первый показ сразу после онбординга.
void openAuth(BuildContext context, {bool intro = false}) {
  Navigator.of(context).push(MaterialPageRoute<void>(settings: RouteSettings(name: 'AuthPage'),builder: (_) => AuthPage(intro: intro)));
}

// Вход в два шага: почта, затем ссылка или код из письма.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.intro = false, this.start = false});

  /// Стартовый экран веб-версии: не закрывается назад, а завершает онбординг.
  final bool start;

  /// После онбординга: объясняем, зачем входить, и даём уйти без входа.
  final bool intro;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController(), _code = TextEditingController();

  /// Почта, на которую ушёл код; null — код ещё не просили.
  String? _sentTo;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _loadEmail();
    if (widget.start && store.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => store.finishOnboarding());
    }
  }

  // Подставляем почту, которую вводили в прошлый раз.
  Future<void> _loadEmail() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_kLastEmail);
      if (saved != null && mounted && _email.text.isEmpty) _email.text = saved;
    } catch (_) {}
  }

  // Вошли — по коду или по ссылке из письма, пока экран был открыт.
  void _onStore() {
    if (store.user == null || !mounted) return;
    widget.start ? store.finishOnboarding() : Navigator.pop(context);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = email.isEmpty ? ui('Введи почту.') : ui('Похоже, в почте опечатка.'));
      return;
    }
    if (!store.canSignIn) {
      setState(() => _error = ui('Вход пока не подключён.'));
      return;
    }
    if (await _run(() => store.sendCode(email))) {
      try {
        (await SharedPreferences.getInstance()).setString(_kLastEmail, email);
      } catch (_) {}
      if (mounted) setState(() => _sentTo = email);
    }
  }

  Future<void> _google() async {
    if (!store.canSignIn) {
      setState(() => _error = ui('Вход пока не подключён.'));
      return;
    }
    await _run(store.signInWithGoogle);
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = ui('Введи код из письма.'));
      return;
    }
    await _run(() => store.verifyCode(_sentTo!, code));
  }

  /// true — запрос прошёл.
  Future<bool> _run(Future<void> Function() request) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      await request();
    } on AuthException catch (e) {
      error = e.statusCode == '429'
          ? ui('Слишком часто. Попробуй через минуту.')
          : (_sentTo == null ? ui('Не получилось отправить код.') : ui('Код не подошёл или устарел.'));
    } catch (_) {
      error = ui('Нет связи. Попробуй ещё раз.');
    }
    if (!mounted) return error == null;
    setState(() {
      _busy = false;
      _error = error;
    });
    return error == null;
  }

  void _changeEmail() {
    _code.clear();
    setState(() {
      _sentTo = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final showcase = wide && (widget.start || widget.intro);
    final form = _form(wide);
    return Scaffold(
      body: SafeArea(
        child: showcase
            ? Row(
                children: [
                  Expanded(flex: 2, child: form),
                  Expanded(child: OnboardingShowcase()),
                ],
              )
            : form,
      ),
    );
  }

  Widget _form(bool wide) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: wide ? Alignment.center : Alignment.topCenter,
                child: ListView(
                  shrinkWrap: true,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    if (widget.intro)
                      SizedBox(height: wide ? 0 : 48)
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(-12, 0),
                          child: IconButton(
                            tooltip: ui('Назад'),
                            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    if (!wide) ...[
                      ExcludeSemantics(child: Image.asset('assets/ill_my_videos.png', height: 150)),
                      SizedBox(height: 24),
                    ],
                    Headline(
                      _sentTo == null
                          ? ui('Войди в\u00A0*аккаунт*')
                          : (kEmailCode ? ui('Введи *код*') : ui('Проверь *почту*')),
                      color: cText,
                      mark: cAccent,
                    ),
                    if (_sentTo != null || widget.intro) ...[
                      SizedBox(height: 14),
                      Text(
                        _sentTo == null
                            ? ui(
                                'Слова, лайки, история и прогресс сохранятся в облаке и не пропадут, если сменишь телефон '
                                'или переустановишь приложение.',
                              )
                            : (kEmailCode
                                  ? ui('Отправили код на {0}. Письмо может идти пару минут.', [_sentTo!])
                                  : ui('Отправили ссылку на {0}. Открой её на этом телефоне — и ты войдёшь.', [
                                      _sentTo!,
                                    ])),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4, color: cMuted),
                      ),
                    ],
                    SizedBox(height: 28),
                    if (_sentTo == null) ...[
                      TextField(
                        key: ValueKey(ui('Почта')),
                        controller: _email,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: [AutofillHints.email],
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() => _error = null),
                        onSubmitted: (_) => _sendCode(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cText),
                        cursorColor: cViolet,
                        decoration: InputDecoration(
                          hintText: ui('Почта'),
                          hintStyle: TextStyle(color: cFaint),
                          errorText: _error,
                          filled: true,
                          fillColor: cCard,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      BigButton(ui('Войти по почте'), onTap: _busy ? null : _sendCode),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _google,
                          icon: CustomPaint(size: Size(22, 22), painter: _GmailPainter()),
                          label: Text(ui('Войти через Gmail')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cText,
                            disabledForegroundColor: cFaint,
                            side: BorderSide(color: cLine),
                            shape: StadiumBorder(),
                            textStyle: TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (kEmailCode) ...[
                        TextField(
                          key: ValueKey(ui('Код из письма')),
                          controller: _code,
                          autocorrect: false,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          autofillHints: [AutofillHints.oneTimeCode],
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() => _error = null),
                          onSubmitted: (_) => _verify(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cText),
                          cursorColor: cViolet,
                          decoration: InputDecoration(
                            hintText: ui('Код из письма'),
                            hintStyle: TextStyle(color: cFaint),
                            errorText: _error,
                            filled: true,
                            fillColor: cCard,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        BigButton(ui('Войти'), onTap: _busy ? null : _verify),
                        SizedBox(height: 4),
                      ],
                      TextButton(
                        onPressed: _busy ? null : _changeEmail,
                        style: TextButton.styleFrom(
                          foregroundColor: cMuted,
                          textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        child: Text(ui('Другая почта')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.intro)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: TextButton(
                  // С лендинга выйти без входа можно только отсюда, поэтому заодно закрываем онбординг.
                  onPressed: () {
                    store.finishOnboarding();
                    if (!widget.start) Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: cMuted,
                    textStyle: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: Text(ui('Смотреть без авторизации')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Логотип Gmail: две цветные боковины и красная «M».
class _GmailPainter extends CustomPainter {
  const _GmailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final fill = Paint()..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(1.5, 5, 4, 14), bottomLeft: Radius.circular(1.5)),
      fill..color = const Color(0xFF4285F4),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(18.5, 5, 4, 14), bottomRight: Radius.circular(1.5)),
      fill..color = const Color(0xFF34A853),
    );
    canvas.drawPath(
      Path()
        ..moveTo(18.5, 5)
        ..lineTo(22.5, 5)
        ..lineTo(22.5, 8)
        ..lineTo(18.5, 11)
        ..close(),
      fill..color = const Color(0xFFFBBC04),
    );
    canvas.drawPath(
      Path()
        ..moveTo(3.5, 7.5)
        ..lineTo(12, 13.8)
        ..lineTo(20.5, 7.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeJoin = StrokeJoin.miter
        ..color = const Color(0xFFEA4335),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
