import 'package:flutter/material.dart';

import 'store.dart';
import 'subs.dart';
import 'theme.dart';

/// Слова фразы: каждое подчёркнуто и нажимается, сохранённые подчёркнуты фиолетовым.
class PhraseWords extends StatelessWidget {
  const PhraseWords(
    this.cue, {
    super.key,
    required this.onWord,
    this.size = 22,
    this.spacing = 7,
    this.pad = 4,
    this.center = false,
  });
  final Cue cue;
  final void Function(String word) onWord;
  final double size, spacing, pad;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: center ? WrapAlignment.center : WrapAlignment.start,
      spacing: spacing,
      children: [
        for (final w in cue.text.split(' '))
          GestureDetector(
            onTap: () => onWord(w),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: pad),
              child: Text(
                store.conv(w),
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: cInk,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                  decorationColor: store.isSaved(toLat(cleanWord(w)).toLowerCase())
                      ? cViolet
                      : cInk.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Шторка со словом: перевод из словарика ролика и кнопка «Добавить в мои слова».
void showWord(
  BuildContext context, {
  required String raw,
  required Cue cue,
  required Map<String, dynamic> dict,
  required String videoId,
  // Вместо времени в ролике: у рассказов здесь страница.
  String? place,
}) {
  final word = cleanWord(raw);
  if (word.isEmpty) return;
  final lat = toLat(word), cyr = toCyr(lat), key = lat.toLowerCase();
  final entry = dict[key] as List?;
  final tr = entry == null ? '' : entry[0] as String;
  final note = entry == null ? '' : entry[1] as String;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: cBg,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
        // В горизонтальном режиме карточка может не поместиться по высоте.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                store.cyr ? cyr : lat,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.6,
                  color: cText,
                ),
              ),
              SizedBox(height: 6),
              Text('${store.cyr ? lat : cyr} · ${place ?? fmtTime(cue.start)}', style: TextStyle(fontSize: 15, color: cMuted)),
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(20)),
                child: Text(store.conv(cue.text), style: TextStyle(fontSize: 15, height: 1.45, color: cText)),
              ),
              SizedBox(height: 14),
              if (entry == null)
                Text('Этого слова нет в словарике ролика.', style: TextStyle(fontSize: 14, color: cMuted))
              else ...[
                Text(
                  tr,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25, color: cAccentText),
                ),
                if (note.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(note, style: TextStyle(fontSize: 14, height: 1.45, color: cMuted)),
                ],
              ],
              SizedBox(height: 16),
              BigButton(
                store.isSaved(key) ? 'Уже в моих словах' : 'Добавить в мои слова',
                onTap: () {
                  store.add(SavedWord(key: key, tr: tr, ctx: cue.text, t: cue.start, video: videoId));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
