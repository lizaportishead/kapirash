import 'dart:ui' as dui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'l10n.dart';

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
  // Кнопка «Мои слова»: при добавлении шторка улетает к ней.
  GlobalKey? flyTo,
}) {
  final word = cleanWord(raw);
  if (word.isEmpty) return;
  final lat = toLat(word), cyr = toCyr(lat), key = lat.toLowerCase();
  final entry = dict[key] as List?;
  final tr = entry == null ? '' : entry[0] as String;
  final note = entry == null ? '' : entry[1] as String;
  final sheetKey = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: cBg,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (ctx) => RepaintBoundary(
      key: sheetKey,
      child: ColoredBox(
        color: cBg,
        child: SafeArea(
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
                Text(ui('Этого слова нет в словарике ролика.'), style: TextStyle(fontSize: 14, color: cMuted))
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
                store.isSaved(key) ? ui('Убрать слово') : ui('Добавить в мои слова'),
                bg: store.isSaved(key) ? cCard : null,
                fg: store.isSaved(key) ? cText : null,
                onTap: () async {
                  final already = store.isSaved(key);
                  if (already) {
                    store.remove(key);
                    if (ctx.mounted) Navigator.pop(ctx);
                    return;
                  }
                  // Снимок шторки и её место снимаем до закрытия.
                  dui.Image? img;
                  Rect? from;
                  final box = sheetKey.currentContext?.findRenderObject();
                  if (!already && flyTo != null && box is RenderRepaintBoundary) {
                    from = box.localToGlobal(Offset.zero) & box.size;
                    img = await box.toImage(pixelRatio: 1);
                  }
                  store.add(SavedWord(key: key, tr: tr, ctx: cue.text, t: cue.start, video: videoId)..setLemmaFrom(dict));
                  if (ctx.mounted) Navigator.pop(ctx);
                  final tb = flyTo?.currentContext?.findRenderObject();
                  if (img != null && from != null && tb is RenderBox && tb.attached) {
                    final to = tb.localToGlobal(Offset.zero) & tb.size;
                    late OverlayEntry entry;
                    entry = OverlayEntry(builder: (_) => _Fly(image: img!, from: from!, to: to, onDone: entry.remove));
                    overlay.insert(entry);
                  }
                },
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

/// Снимок шторки сжимается и летит к кнопке «Мои слова».
class _Fly extends StatefulWidget {
  const _Fly({required this.image, required this.from, required this.to, required this.onDone});
  final dui.Image image;
  final Rect from, to;
  final VoidCallback onDone;

  @override
  State<_Fly> createState() => _FlyState();
}

class _FlyState extends State<_Fly> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: 600))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.from, to = widget.to;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(_c.value);
          final c = Offset.lerp(from.center, to.center, t)!;
          final scale = dui.lerpDouble(1, 0.06, t)!;
          final opacity = 1 - Curves.easeIn.transform((_c.value - 0.6).clamp(0, 0.4) / 0.4);
          return Stack(
            children: [
              Positioned(
                left: c.dx - from.width / 2,
                top: c.dy - from.height / 2,
                width: from.width,
                height: from.height,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: RawImage(image: widget.image, fit: BoxFit.fill),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
