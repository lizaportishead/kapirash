import 'dart:convert';
import 'dart:ui' as dui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'store.dart';
import 'subs.dart';
import 'theme.dart';
import 'l10n.dart';

/// Слова фразы: каждое подчёркнуто и нажимается, сохранённые подчёркнуты фиолетовым.
/// Долгое нажатие на слово и движение пальца выделяют фразу; когда палец отпущен, открывается шторка.
class PhraseWords extends StatefulWidget {
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
  final void Function(String word, Rect at) onWord;
  final double size, spacing, pad;
  final bool center;

  @override
  State<PhraseWords> createState() => _PhraseWordsState();
}

class _PhraseWordsState extends State<PhraseWords> {
  int? _from, _to;
  List<GlobalKey> _keys = [];

  @override
  void didUpdateWidget(PhraseWords old) {
    super.didUpdateWidget(old);
    if (old.cue.text != widget.cue.text) _from = _to = null;
  }

  /// Слово под пальцем; если палец между словами или вне фразы, берём ближайшее по строке.
  int? _wordAt(Offset global) {
    int? best;
    var bestD = double.infinity;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final r = box.localToGlobal(Offset.zero) & box.size;
      final d = (r.inflate(widget.spacing).contains(global)) ? 0.0 : (r.center - global).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void _finish(List<String> words) {
    final a = _from, b = _to;
    setState(() => _from = _to = null);
    if (a == null || b == null) return;
    final lo = a < b ? a : b, hi = a < b ? b : a;
    widget.onWord(words.sublist(lo, hi + 1).join(' '), _rectOf(lo));
  }

  /// Прямоугольник слова в экранных координатах: возле него показываем карточку перевода.
  Rect _rectOf(int i) {
    final box = _keys[i].currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.cue.text.split(' ');
    if (_keys.length != words.length) _keys = List.generate(words.length, (_) => GlobalKey());
    final a = _from, b = _to;
    final lo = a == null || b == null ? -1 : (a < b ? a : b);
    final hi = a == null || b == null ? -1 : (a < b ? b : a);
    return Wrap(
      alignment: widget.center ? WrapAlignment.center : WrapAlignment.start,
      children: [
        for (var i = 0; i < words.length; i++)
          GestureDetector(
            key: _keys[i],
            onTap: () => widget.onWord(words[i], _rectOf(i)),
            onLongPressStart: (d) => setState(() => _from = _to = i),
            onLongPressMoveUpdate: (d) {
              final j = _wordAt(d.globalPosition);
              if (j != null && j != _to) setState(() => _to = j);
            },
            onLongPressEnd: (_) => _finish(words),
            onLongPressCancel: () => setState(() => _from = _to = null),
            child: Padding(
              padding: EdgeInsets.only(right: i >= lo && i < hi ? 0 : widget.spacing),
              child: Container(
                decoration: BoxDecoration(
                  color: i >= lo && i <= hi ? cViolet.withValues(alpha: 0.3) : null,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(i == lo ? 6 : 0),
                    right: Radius.circular(i == hi ? 6 : 0),
                  ),
                ),
                // Отступ справа внутри слова, чтобы пробел между выделенными словами тоже закрашивался.
                padding: EdgeInsets.only(
                  top: widget.pad,
                  bottom: widget.pad,
                  right: i >= lo && i < hi ? widget.spacing : 0,
                ),
                child: Text(
                  store.conv(words[i]),
                  style: TextStyle(
                    fontSize: widget.size,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: cInk,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                    decorationColor: store.isSaved(toLat(cleanWord(words[i])).toLowerCase())
                        ? cViolet
                        : cInk.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Перевод всей фразы целиком; null, если сервис недоступен.
Future<String?> _translatePhrase(String lat) async {
  try {
    final to = store.lang == 'en' ? 'en' : 'ru';
    final r = await http
        .get(Uri.https('api.mymemory.translated.net', '/get', {'q': toCyr(lat), 'langpair': 'sr|$to'}))
        .timeout(Duration(seconds: 8));
    final t = (jsonDecode(utf8.decode(r.bodyBytes))['responseData']?['translatedText'] as String?)?.trim();
    return t == null || t.isEmpty ? null : t;
  } catch (_) {
    return null;
  }
}

/// Шторка со словом: перевод из словарика ролика и кнопка «Сохранить в словарь».
void showWord(
  BuildContext context, {
  required String raw,
  required Cue cue,
  required Map<String, dynamic> dict,
  required String videoId,
  // Вместо времени в ролике: у рассказов здесь страница.
  String? place,
  // Кнопка «Словарь»: при добавлении шторка улетает к ней.
  GlobalKey? flyTo,
}) {
  if (cleanWord(raw).isEmpty) return;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      margin: EdgeInsets.fromLTRB(10, 0, 10, 10 + MediaQuery.of(ctx).padding.bottom * 0.5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(32)),
      child: WordCard(
        raw: raw,
        cue: cue,
        dict: dict,
        videoId: videoId,
        place: place,
        flyTo: flyTo,
        onClose: () => Navigator.pop(ctx),
      ),
    ),
  );
}

/// Кнопка-ссылка в строке под переводом.
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.icon, required this.label, required this.url});
  final Widget icon;
  final String label;
  final Uri url;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: SizedBox(width: 18, height: 18, child: Center(child: icon)),
    label: Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cMuted),
    ),
    onPressed: () => launchUrl(url, mode: LaunchMode.externalApplication),
  );
}

/// Карточка слова: в шторке на телефоне и в правой колонке на десктопе.
class WordCard extends StatefulWidget {
  const WordCard({
    super.key,
    required this.raw,
    required this.cue,
    required this.dict,
    required this.videoId,
    required this.onClose,
    this.place,
    this.flyTo,
    this.compact = false,
  });
  final bool compact;
  final String raw, videoId;
  final Cue cue;
  final Map<String, dynamic> dict;
  final String? place;
  final GlobalKey? flyTo;
  final VoidCallback onClose;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  final sheetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cue = widget.cue, dict = widget.dict, flyTo = widget.flyTo;
    final parts = [
      for (final p in widget.raw.split(RegExp(r'\s+')))
        if (cleanWord(p).isNotEmpty) cleanWord(p),
    ];
    if (parts.isEmpty) return SizedBox.shrink();
    final word = parts.join(' ');
    final lat = toLat(word), cyr = toCyr(lat), key = lat.toLowerCase();
    final isPhrase = parts.length > 1;
    // У фразы своей записи в словарике нет: перевод собираем из слов.
    final entry = isPhrase ? null : dict[key] as List?;
    final partTr = [
      for (final p in parts)
        if (dict[toLat(p).toLowerCase()] case final List e) '${toLat(p).toLowerCase()} — ${e[0]}',
    ];
    final wordsTr = partTr.map((l) => l.split(' — ').last).join(' · ');
    final phraseTr = isPhrase ? _translatePhrase(lat) : null;
    final tr = isPhrase ? wordsTr : (entry == null ? '' : entry[0] as String);
    final note = entry == null ? '' : entry[1] as String;
    final overlay = Overlay.of(context, rootOverlay: true);
    return RepaintBoundary(
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
                      fontSize: isPhrase ? 26 : 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.6,
                      color: cText,
                    ),
                  ),
                  SizedBox(height: 14),
                  if (isPhrase)
                    FutureBuilder<String?>(
                      future: phraseTr,
                      builder: (_, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return Text(
                            '…',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cMuted),
                          );
                        }
                        return Text(
                          snap.data ?? wordsTr,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25, color: cAccentText),
                        );
                      },
                    )
                  else if (entry == null)
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
                  if (!isPhrase) SizedBox(height: 10),
                  if (!isPhrase)
                    Wrap(
                      spacing: 8,
                      children: [
                        LinkButton(
                          icon: Image.asset('assets/glosbe.png', width: 18, height: 18),
                          label: ui('Смотреть в Glosbe'),
                          url: Uri.https('glosbe.com', '/sr/${store.lang == 'en' ? 'en' : 'ru'}/$cyr'),
                        ),
                        LinkButton(
                          icon: Text(
                            'W',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: cMuted,
                            ),
                          ),
                          label: ui('Смотреть в Wiktionary'),
                          url: Uri.https(
                            'en.wiktionary.org',
                            '/wiki/${SavedWord.lemmaOf(key, note)}',
                          ).replace(fragment: 'Serbo-Croatian'),
                        ),
                      ],
                    ),
                  SizedBox(height: 12),
                  BigButton(
                    compact: widget.compact,
                    store.isSaved(key)
                        ? ui(isPhrase ? 'Убрать фразу' : 'Убрать слово')
                        : ui(isPhrase ? 'Сохранить фразу в словарь' : 'Сохранить в словарь'),
                    bg: store.isSaved(key) ? cCard : null,
                    fg: store.isSaved(key) ? cText : null,
                    onTap: () async {
                      final already = store.isSaved(key);
                      if (already) {
                        store.remove(key);
                        if (mounted) widget.onClose();
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
                      store.add(
                        SavedWord(
                          key: key,
                          tr: (isPhrase ? await phraseTr : null) ?? tr,
                          ctx: cue.text,
                          t: cue.start,
                          video: widget.videoId,
                        )..setLemmaFrom(dict),
                      );
                      if (mounted) widget.onClose();
                      final tb = flyTo?.currentContext?.findRenderObject();
                      if (img != null && from != null && tb is RenderBox && tb.attached) {
                        final to = tb.localToGlobal(Offset.zero) & tb.size;
                        late OverlayEntry entry;
                        entry = OverlayEntry(
                          builder: (_) => _Fly(image: img!, from: from!, to: to, onDone: entry.remove),
                        );
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
    );
  }
}

/// Снимок шторки сжимается и летит к кнопке «Словарь».
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
