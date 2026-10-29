import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'l10n.dart';
import 'store.dart';
import 'supabase_config.dart';
import 'theme.dart';

void openFeedback(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'FeedbackPage'),
      builder: (_) => FeedbackPage(),
    ),
  );
}

/// Форма обратной связи: текст уходит в функцию feedback (supabase/functions/feedback), оттуда в Telegram.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _text = TextEditingController();
  final _contact = TextEditingController();
  bool _sending = false, _sent = false;

  @override
  void dispose() {
    _text.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final r = await http
          .post(
            Uri.parse('$supabaseUrl/functions/v1/feedback'),
            headers: {'apikey': supabaseKey, 'content-type': 'application/json'},
            body: jsonEncode({
              'text': _text.text,
              'contact': _contact.text,
              'from': store.user ?? '',
              'lang': store.lang,
              'platform': Theme.of(context).platform.name,
            }),
          )
          .timeout(Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception(r.statusCode);
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ui('Не получилось отправить. Напиши на info@kapiras.app'))));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...pageHeader(context, ui('Обратная связь')),
                      Expanded(child: _sent ? _thanks() : _form()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thanks() => Center(
    child: Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Text(
        ui('Спасибо! Сообщение отправлено.'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, height: 1.45, color: cMuted),
      ),
    ),
  );

  Widget _form() => ListView(
    padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
    children: [
      TextField(
        controller: _text,
        minLines: 5,
        maxLines: 10,
        maxLength: 2000,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: ui('Что понравилось, что сломалось, чего не хватает?'), border: OutlineInputBorder()),
      ),
      SizedBox(height: 12),
      TextField(
        controller: _contact,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: ui('Почта или Telegram, чтобы ответить (необязательно)'),
          border: OutlineInputBorder(),
        ),
      ),
      SizedBox(height: 20),
      BigButton(
        _sending ? ui('Отправляю…') : ui('Отправить'),
        onTap: _sending || _text.text.trim().length < 3 ? null : _send,
      ),
    ],
  );
}
