import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adaptive_sheet.dart';
import 'l10n.dart';
import 'request_sheet.dart';
import 'stories_page.dart';
import 'story_import.dart';
import 'store.dart';
import 'theme.dart';

/// Пока свои рассказы доступны одному аккаунту.
const kStoryOwnerEmail = 'iamkurm@gmail.com';
bool get canAddStory => kDebugMode || store.user == kStoryOwnerEmail;

Future<void> showAddStory(BuildContext context) async {
  final ok = await showAdaptiveSheet<bool>(context, (_) => _AddStorySheet());
  if (ok == true && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(ui('Рассказ добавлен. Читать можно сразу, словарик появится после обработки.'))),
    );
  }
}

class _AddStorySheet extends StatefulWidget {
  const _AddStorySheet();

  @override
  State<_AddStorySheet> createState() => _AddStorySheetState();
}

class _AddStorySheetState extends State<_AddStorySheet> {
  final _title = TextEditingController(), _author = TextEditingController(), _text = TextEditingController();
  String _level = 'A2';
  String? _error, _note;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: formats);
    if (f == null) return;
    try {
      final t = importFile(f.name, await f.readAsBytes());
      setState(() {
        _text.text = t.text;
        if (_title.text.trim().isEmpty) _title.text = t.title.isNotEmpty ? t.title : f.name.replaceFirst(RegExp(r'\.\w+$'), '');
        if (_author.text.trim().isEmpty) _author.text = t.author;
        _error = null;
        _note = t.cut ? ui('Текст длиннее {0} стр., лишнее отрезано.', [kStoryMaxPages]) : null;
      });
    } catch (e) {
      setState(() => _error = ui('Не получилось прочитать файл: {0}', ['$e'.replaceFirst('FormatException: ', '')]));
    }
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || !mounted) return;
    final t = prepareText(text);
    setState(() {
      _text.text = t.text;
      _note = t.cut ? ui('Текст длиннее {0} стр., лишнее отрезано.', [kStoryMaxPages]) : null;
      _error = null;
    });
  }

  Future<void> _save() async {
    final t = prepareText(_text.text);
    final title = _title.text.trim();
    if (title.isEmpty) return setState(() => _error = ui('Напиши название.'));
    if (t.text.length < 200) return setState(() => _error = ui('Текст слишком короткий.'));
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await cloud!.from('my_stories').insert({
        'title': prepareText(title).text,
        'author': prepareText(_author.text.trim()).text,
        'level': _level,
        'body': t.text,
        'pages': pageCount(t.text),
      });
      await loadMyStories();
      // Уведомление в Telegram; если не дошло, рассказ всё равно в очереди.
      sendRequest('🆕 Заявка: рассказ «$title», ${pageCount(t.text)} стр.').catchError((_) {});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ui('Не удалось сохранить: {0}', ['$e']);
        });
      }
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cFaint),
    filled: true,
    fillColor: cBg,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    final pages = pageCount(_text.text);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ui('Добавить рассказ'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: cText),
            ),
            SizedBox(height: 6),
            Text(
              ui(
                'Вставь текст на сербском или выбери файл (TXT, FB2, EPUB, DOCX), до {0} страниц. Кириллица станет латиницей. '
                'Рассказ увидишь только ты.',
                [kStoryMaxPages],
              ),
              style: TextStyle(fontSize: 14, height: 1.45, color: cMuted),
            ),
            SizedBox(height: 14),
            TextField(controller: _title, enabled: !_busy, style: TextStyle(color: cText), cursorColor: cViolet, decoration: _dec(ui('Название'))),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _author, enabled: !_busy, style: TextStyle(color: cText), cursorColor: cViolet, decoration: _dec(ui('Автор'))),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _level,
                  dropdownColor: cCard,
                  underline: SizedBox.shrink(),
                  style: TextStyle(fontSize: 15, color: cText),
                  items: [for (final l in ['A1', 'A2', 'B1', 'B2', 'C1']) DropdownMenuItem(value: l, child: Text(l))],
                  onChanged: _busy ? null : (v) => setState(() => _level = v!),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _text,
              enabled: !_busy,
              minLines: 5,
              maxLines: 8,
              onChanged: (_) => setState(() => _error = null),
              style: TextStyle(fontSize: 14, color: cText),
              cursorColor: cViolet,
              decoration: _dec(ui('Текст рассказа')),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _pickFile,
                  icon: Icon(Icons.attach_file_rounded, size: 18, color: cViolet),
                  label: Text(ui('Выбрать файл'), style: TextStyle(color: cViolet)),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _paste,
                  icon: Icon(Icons.content_paste_rounded, size: 18, color: cViolet),
                  label: Text(ui('Вставить'), style: TextStyle(color: cViolet)),
                ),
                Spacer(),
                if (pages > 0) Text(ui('{0} стр.', [pages]), style: TextStyle(fontSize: 13, color: cMuted)),
              ],
            ),
            if (_note != null) Padding(padding: EdgeInsets.only(top: 4), child: Text(_note!, style: TextStyle(fontSize: 13, color: cMuted))),
            if (_error != null) Padding(padding: EdgeInsets.only(top: 4), child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.redAccent))),
            SizedBox(height: 12),
            BigButton(_busy ? ui('Сохраняем…') : ui('Добавить'), onTap: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}
