import 'package:flutter/material.dart';

import 'store.dart';
import 'theme.dart';

/// Аккаунт, под которым «входят» кнопки Apple и Google.
const mockEmail = 'anya@example.com';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Открывает вход поверх таббара.
void openAuth(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => AuthPage()));
}

// Бэкенда пока нет — вход замокан: любая почта и обе кнопки сразу «входят» и возвращают назад.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = email.isEmpty ? 'Введи почту.' : 'Похоже, в почте опечатка.');
      return;
    }
    _signIn(email);
  }

  void _signIn(String email) {
    store.signIn(email);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(-12, 0),
                    child: IconButton(
                      tooltip: 'Назад',
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Sticker('Kapiraš', color: cViolet, fg: cOnViolet, angle: -0.07),
                ),
                SizedBox(height: 28),
                Headline('ВОЙДИ В *АККАУНТ.*', color: cText, mark: cAccent),
                SizedBox(height: 14),
                Text(
                  'Хватит почты — пароль придумывать не нужно.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4, color: cMuted),
                ),
                SizedBox(height: 28),
                TextField(
                  controller: _email,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: [AutofillHints.email],
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cText),
                  cursorColor: cViolet,
                  decoration: InputDecoration(
                    hintText: 'Почта',
                    hintStyle: TextStyle(color: cFaint),
                    errorText: _error,
                    filled: true,
                    fillColor: cCard,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: 12),
                BigButton('Продолжить', onTap: _submit),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: cLine)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'или',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFaint),
                        ),
                      ),
                      Expanded(child: Divider(color: cLine)),
                    ],
                  ),
                ),
                _Social(
                  icon: Icon(Icons.apple, size: 24, color: cText),
                  text: 'Продолжить с Apple',
                  onTap: () => _signIn(mockEmail),
                ),
                SizedBox(height: 10),
                _Social(
                  icon: Text(
                    'G',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1, color: cText),
                  ),
                  text: 'Продолжить с Google',
                  onTap: () => _signIn(mockEmail),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Social extends StatelessWidget {
  const _Social({required this.icon, required this.text, required this.onTap});
  final Widget icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: cText,
          side: BorderSide(color: cLine, width: 1.5),
          shape: StadiumBorder(),
          textStyle: TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox(width: 24, child: Center(child: icon)),
            ),
            SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }
}
