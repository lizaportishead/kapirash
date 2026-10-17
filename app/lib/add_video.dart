import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'player_page.dart';
import 'store.dart';
import 'theme.dart';
import 'videos.dart';

/// Кнопка «+» в каталоге видна только владельцу: пока ролики добавляет один человек.
const kOwnerEmails = {'ilovekurm@gmail.com', 'iamkurm@gmail.com'};
bool get canAddVideo => kDebugMode || kOwnerEmails.contains(store.user);

/// Шторка «Добавить ролик». После ссылки открывает экран ролика: на нём видно, как идёт подготовка.
Future<void> showAddVideo(BuildContext context) async {
  final video = await showModalBottomSheet<Video>(
    context: context,
    backgroundColor: cBg,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => _AddVideoSheet(),
  );
  if (video != null && context.mounted) openVideo(context, video);
}

class _NotFound implements Exception {}

/// Название и канал ролика с YouTube. Если YouTube не ответил, ролик всё равно добавляем — без названия.
Future<Video> _fetchVideo(String id) async {
  var title = 'Ролик с YouTube', channel = 'YouTube';
  try {
    final r = await http
        .get(Uri.https('www.youtube.com', '/oembed', {'url': 'https://www.youtube.com/watch?v=$id', 'format': 'json'}))
        .timeout(Duration(seconds: 8));
    if (r.statusCode == 400 || r.statusCode == 404) throw _NotFound();
    if (r.statusCode == 200) {
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      title = j['title'] as String? ?? title;
      channel = j['author_name'] as String? ?? channel;
    }
  } on _NotFound {
    rethrow;
  } catch (_) {}
  return Video(id: id, title: title, channel: channel, mine: true);
}

class _AddVideoSheet extends StatefulWidget {
  const _AddVideoSheet();

  @override
  State<_AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends State<_AddVideoSheet> {
  final _link = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || !mounted) return;
    setState(() {
      _link.text = text.trim();
      _error = null;
    });
  }

  Future<void> _add() async {
    final id = parseVideoId(_link.text);
    if (id == null) {
      setState(() => _error = 'Не похоже на ссылку YouTube. Вставь ссылку на ролик целиком.');
      return;
    }
    // Ролик уже есть в каталоге или в своих — просто открываем его.
    final known = videoById(id);
    if (known != null) {
      Navigator.pop(context, known);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final v = await _fetchVideo(id);
      if (!mounted) return;
      store.addVideo(v);
      Navigator.pop(context, v);
    } on _NotFound {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Не нашли такой ролик на YouTube. Проверь ссылку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Добавить ролик',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: cText),
            ),
            SizedBox(height: 6),
            Text(
              'Вставь ссылку на ролик YouTube на сербском — мы подготовим к нему субтитры, перевод и словарик. '
              'Ролик и его текст будут видны только тебе и хранятся на этом устройстве.',
              style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
            ),
            SizedBox(height: 14),
            TextField(
              controller: _link,
              autofocus: true,
              enabled: !_busy,
              autocorrect: false,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _add(),
              style: TextStyle(fontSize: 15, color: cText),
              cursorColor: cViolet,
              decoration: InputDecoration(
                hintText: 'https://youtu.be/…',
                hintStyle: TextStyle(color: cFaint),
                errorText: _error,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: 'Вставить из буфера',
                  icon: Icon(Icons.content_paste_rounded, size: 20, color: cMuted),
                  onPressed: _busy ? null : _paste,
                ),
                filled: true,
                fillColor: cCard,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 16),
            BigButton(_busy ? 'Добавляем…' : 'Добавить', onTap: _busy ? null : _add),
          ],
        ),
      ),
    );
  }
}
