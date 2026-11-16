import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'adaptive_sheet.dart';
import 'l10n.dart';
import 'store.dart';
import 'supabase_config.dart';
import 'theme.dart';

/// Пока заявки на ролики и подкасты может слать один аккаунт.
const kRequestEmail = 'iamkurm@gmail.com';
bool get canSendRequest => kDebugMode || store.user == kRequestEmail;

/// Шлёт заявку в Telegram через функцию feedback (токен бота лежит в секретах Supabase, в приложении его нет).
Future<void> sendRequest(String text) async {
  final r = await http
      .post(
        Uri.parse('$supabaseUrl/functions/v1/feedback'),
        headers: {'apikey': supabaseKey, 'content-type': 'application/json'},
        body: jsonEncode({'text': text, 'contact': store.user ?? '', 'from': store.user ?? '', 'lang': store.lang, 'platform': 'request'}),
      )
      .timeout(Duration(seconds: 12));
  if (r.statusCode != 200) throw Exception(r.statusCode);
}

/// Шторка «Заявка на ролик / подкаст»: ссылка и заметка уходят в Telegram, пользователю — «заявка отправлена».
Future<void> showSendRequest(BuildContext context, {required bool podcast}) =>
    showAdaptiveSheet<void>(context, (_) => _RequestSheet(podcast: podcast));

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.podcast});
  final bool podcast;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _link = TextEditingController(), _note = TextEditingController();
  bool _busy = false, _sent = false;
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text != null && mounted) setState(() => _link.text = text.trim());
  }

  Future<void> _send() async {
    final link = _link.text.trim();
    if (!link.startsWith('http')) return setState(() => _error = ui('Вставь ссылку целиком, она начинается с https://'));
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final kind = widget.podcast ? ui('подкаст') : ui('ролик');
      await sendRequest('🆕 Заявка: $kind\n$link${_note.text.trim().isEmpty ? '' : '\n\n${_note.text.trim()}'}');
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ui('Не получилось отправить. Попробуй ещё раз.');
        });
      }
    }
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cFaint),
    suffixIcon: suffix,
    filled: true,
    fillColor: cBg,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    final podcast = widget.podcast;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _sent
              ? [
                  Text(ui('Заявка отправлена'), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: cText)),
                  SizedBox(height: 6),
                  Text(
                    ui('Мы подготовим субтитры, перевод и словарик, а когда будет готово, материал появится в приложении.'),
                    style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                  ),
                  SizedBox(height: 16),
                  BigButton(ui('Готово'), onTap: () => Navigator.pop(context)),
                ]
              : [
                  Text(
                    podcast ? ui('Заявка на подкаст') : ui('Заявка на ролик'),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: cText),
                  ),
                  SizedBox(height: 6),
                  Text(
                    podcast
                        ? ui('Вставь ссылку на эпизод: страница на podcast.rs или прямая ссылка на mp3.')
                        : ui('Вставь ссылку на ролик YouTube на сербском.'),
                    style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
                  ),
                  SizedBox(height: 14),
                  TextField(
                    controller: _link,
                    autofocus: true,
                    enabled: !_busy,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() => _error = null),
                    style: TextStyle(fontSize: 15, color: cText),
                    cursorColor: cViolet,
                    decoration: _dec(
                      'https://…',
                      suffix: IconButton(
                        tooltip: ui('Вставить из буфера'),
                        icon: Icon(Icons.content_paste_rounded, size: 20, color: cMuted),
                        onPressed: _busy ? null : _paste,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    enabled: !_busy,
                    maxLines: 2,
                    style: TextStyle(fontSize: 14, color: cText),
                    cursorColor: cViolet,
                    decoration: _dec(ui('Комментарий (необязательно)')),
                  ),
                  if (_error != null) Padding(padding: EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.redAccent))),
                  SizedBox(height: 16),
                  BigButton(_busy ? ui('Отправляем…') : ui('Отправить заявку'), onTap: _busy ? null : _send),
                ],
        ),
      ),
    );
  }
}
