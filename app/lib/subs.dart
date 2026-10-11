class Cue {
  Cue(this.start, this.end, this.text);
  final double start;
  double end;
  final String text;
}

double _ts(String t) {
  final p = t.trim().replaceAll(',', '.').split(':').map(double.parse).toList();
  return p.length == 3 ? p[0] * 3600 + p[1] * 60 + p[2] : p[0] * 60 + p[1];
}

final _timing = RegExp(r'([\d:.,]+)\s*-->\s*([\d:.,]+)');
final _auto = RegExp(r'<\d\d:\d\d:\d\d\.\d+>|<c>');

String _strip(String s) => s
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// SRT / VTT, включая автосубтитры YouTube.
List<Cue> parseSubs(String text) {
  final raw = <(double, double, List<String>)>[];
  for (final b in text.replaceAll('\r', '').split(RegExp(r'\n\n+'))) {
    final lines = b.split('\n');
    final i = lines.indexWhere((l) => l.contains('-->'));
    if (i < 0) continue;
    final m = _timing.firstMatch(lines[i]);
    if (m == null) continue;
    raw.add((_ts(m[1]!), _ts(m[2]!), lines.sublist(i + 1)));
  }
  final cues = <Cue>[];
  if (_auto.hasMatch(text)) {
    for (final (start, end, lines) in raw) {
      final fresh = lines.where(_auto.hasMatch).map(_strip).join(' ').trim();
      if (fresh.isNotEmpty) cues.add(Cue(start, end, fresh));
    }
    for (var k = 0; k < cues.length - 1; k++) {
      if (cues[k + 1].start > cues[k].end) cues[k].end = cues[k + 1].start;
    }
  } else {
    for (final (start, end, lines) in raw) {
      final t = _strip(lines.join(' '));
      if (t.isNotEmpty) cues.add(Cue(start, end, t));
    }
  }
  return cues;
}

int cueAt(List<Cue> list, double t) {
  for (var i = 0; i < list.length; i++) {
    if (t >= list[i].start && t < list[i].end) return i;
  }
  return -1;
}

String fmtTime(double sec) {
  final s = sec.floor();
  final h = s ~/ 3600, m = s % 3600 ~/ 60, x = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$x' : '$m:$x';
}

// ---- транслитерация ----
const _l2c = {
  'a': 'а',
  'b': 'б',
  'c': 'ц',
  'č': 'ч',
  'ć': 'ћ',
  'd': 'д',
  'dž': 'џ',
  'đ': 'ђ',
  'e': 'е',
  'f': 'ф',
  'g': 'г',
  'h': 'х',
  'i': 'и',
  'j': 'ј',
  'k': 'к',
  'l': 'л',
  'lj': 'љ',
  'm': 'м',
  'n': 'н',
  'nj': 'њ',
  'o': 'о',
  'p': 'п',
  'r': 'р',
  's': 'с',
  'š': 'ш',
  't': 'т',
  'u': 'у',
  'v': 'в',
  'z': 'з',
  'ž': 'ж',
};
final _c2l = {for (final e in _l2c.entries) e.value: e.key};

String _caseLike(String src, String out) =>
    src[0] != src[0].toLowerCase() ? out[0].toUpperCase() + out.substring(1) : out;

String toCyr(String s) => s.replaceAllMapped(RegExp(r'lj|nj|dž|.', caseSensitive: false, unicode: true), (m) {
  final c = _l2c[m[0]!.toLowerCase()];
  return c == null ? m[0]! : _caseLike(m[0]!, c);
});

String toLat(String s) => s.replaceAllMapped(RegExp(r'.', unicode: true), (m) {
  final c = _c2l[m[0]!.toLowerCase()];
  return c == null ? m[0]! : _caseLike(m[0]!, c);
});

String cleanWord(String w) => w.replaceAll(RegExp(r"[^\p{L}\p{N}'-]", unicode: true), '');
