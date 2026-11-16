import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Лимит: 300 страниц по ~560 знаков, как считает читалка.
const kStoryMaxPages = 300;
const kStoryMaxChars = kStoryMaxPages * 560;

class ImportedText {
  const ImportedText(this.text, {this.title = '', this.author = '', this.cut = false});
  final String text;
  final String title, author;

  /// Текст был длиннее лимита, и его обрезали по абзацу.
  final bool cut;
}

const formats = ['txt', 'fb2', 'epub', 'docx'];

/// Достаёт из файла чистый текст (абзацы через пустую строку), название и автора, если они есть.
ImportedText importFile(String name, Uint8List bytes) {
  final ext = name.toLowerCase().split('.').last;
  switch (ext) {
    case 'fb2':
      return _fb2(_decode(bytes));
    case 'epub':
      return _epub(bytes);
    case 'docx':
      return _docx(bytes);
    case 'txt':
      return prepareText(_decode(bytes));
  }
  throw FormatException('Формат .$ext не поддерживается');
}

/// Чистит текст, переводит кириллицу в латиницу и режет по лимиту.
ImportedText prepareText(String raw, {String title = '', String author = ''}) {
  var t = _latin(raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll(' ', ' '));
  t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
  // Строки внутри абзаца склеиваем, если абзацы разделены пустой строкой; иначе каждая строка — абзац.
  final hasBlank = RegExp(r'\n\s*\n').hasMatch(t);
  final paras = hasBlank
      ? t.split(RegExp(r'\n\s*\n')).map((p) => p.replaceAll('\n', ' ').trim())
      : t.split('\n').map((p) => p.trim());
  final out = <String>[];
  var size = 0, cut = false;
  for (final p in paras) {
    if (p.isEmpty) continue;
    if (size + p.length > kStoryMaxChars) {
      cut = true;
      break;
    }
    out.add(p);
    size += p.length + 2;
  }
  return ImportedText(out.join('\n\n'), title: _latin(title), author: _latin(author), cut: cut);
}

/// Число страниц так же, как их режет читалка (≈560 знаков).
int pageCount(String text) => (text.length / 560).ceil();

String _decode(Uint8List b) {
  try {
    return utf8.decode(b);
  } catch (_) {
    // Старые файлы бывают в Windows-1251.
    return String.fromCharCodes([for (final c in b) c < 0x80 ? c : _cp1251[c - 0x80]]);
  }
}

ImportedText _fb2(String s) {
  final doc = XmlDocument.parse(s.replaceFirst(RegExp(r'^﻿'), ''));
  String? first(XmlElement? e, String tag) =>
      e?.findAllElements(tag).map((x) => x.innerText.trim()).where((x) => x.isNotEmpty).firstOrNull;
  final info = doc.findAllElements('title-info').firstOrNull;
  final title = first(info, 'book-title') ?? '';
  final a = info?.findAllElements('author').firstOrNull;
  final author = [first(a, 'first-name'), first(a, 'last-name')].whereType<String>().join(' ');
  final paras = <String>[];
  for (final body in doc.findAllElements('body')) {
    // Примечания (<body name="notes">) в текст не берём.
    if (body.getAttribute('name') == 'notes') continue;
    for (final p in body.findAllElements('p')) {
      final t = p.innerText.trim();
      if (t.isNotEmpty) paras.add(t);
    }
  }
  return prepareText(paras.join('\n\n'), title: title, author: author);
}

ImportedText _docx(Uint8List bytes) {
  final f = ZipDecoder().decodeBytes(bytes).findFile('word/document.xml');
  if (f == null) throw FormatException('Это не документ Word');
  final doc = XmlDocument.parse(utf8.decode(f.content as List<int>));
  final paras = [
    for (final p in doc.findAllElements('w:p'))
      p.findAllElements('w:t').map((t) => t.innerText).join().trim(),
  ].where((p) => p.isNotEmpty);
  return prepareText(paras.join('\n\n'));
}

ImportedText _epub(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  String read(String path) {
    final f = zip.findFile(path) ?? zip.findFile(Uri.decodeFull(path));
    if (f == null) throw FormatException('В EPUB нет файла $path');
    return utf8.decode(f.content as List<int>, allowMalformed: true);
  }

  final container = XmlDocument.parse(read('META-INF/container.xml'));
  final opfPath = container.findAllElements('rootfile').first.getAttribute('full-path')!;
  final opf = XmlDocument.parse(read(opfPath));
  final dir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
  final manifest = {
    for (final i in opf.findAllElements('item')) i.getAttribute('id')!: i.getAttribute('href')!,
  };
  String? meta(String tag) => opf.findAllElements(tag).map((e) => e.innerText.trim()).firstOrNull;
  final paras = <String>[];
  for (final ref in opf.findAllElements('itemref')) {
    final href = manifest[ref.getAttribute('idref')];
    if (href == null) continue;
    try {
      final html = XmlDocument.parse(read('$dir$href'));
      for (final p in html.findAllElements('p')) {
        final t = p.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (t.isNotEmpty) paras.add(t);
      }
    } catch (_) {
      // Глава, которая не разобралась как XML, пропускается.
    }
    if (paras.join().length > kStoryMaxChars * 2) break;
  }
  return prepareText(paras.join('\n\n'), title: meta('dc:title') ?? '', author: meta('dc:creator') ?? '');
}

// Сербская кириллица → латиница. Остальные кириллические буквы (русские) — по ближайшему звуку.
const _cyr = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'ђ': 'đ', 'е': 'e', 'ж': 'ž', 'з': 'z', 'и': 'i',
  'ј': 'j', 'к': 'k', 'л': 'l', 'љ': 'lj', 'м': 'm', 'н': 'n', 'њ': 'nj', 'о': 'o', 'п': 'p', 'р': 'r',
  'с': 's', 'т': 't', 'ћ': 'ć', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c', 'ч': 'č', 'џ': 'dž', 'ш': 'š',
  'ы': 'i', 'э': 'e', 'ю': 'ju', 'я': 'ja', 'й': 'j', 'ё': 'e', 'щ': 'šč', 'ь': '', 'ъ': '',
};

String _latin(String s) {
  if (!RegExp(r'[Ѐ-ӿ]').hasMatch(s)) return s;
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final low = c.toLowerCase();
    final l = _cyr[low];
    if (l == null) {
      b.write(c);
    } else if (c == low || l.isEmpty) {
      b.write(l);
    } else {
      // Заглавная: Lj, Nj, Dž — только первая буква большая.
      b.write(l[0].toUpperCase() + l.substring(1));
    }
  }
  return b.toString();
}

// Верхняя половина Windows-1251 (0x80–0xFF) в Unicode.
const _cp1251 = [
  0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021, 0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
  0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0x0098, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
  0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7, 0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
  0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7, 0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
  0x0410, 0x0411, 0x0412, 0x0413, 0x0414, 0x0415, 0x0416, 0x0417, 0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E, 0x041F,
  0x0420, 0x0421, 0x0422, 0x0423, 0x0424, 0x0425, 0x0426, 0x0427, 0x0428, 0x0429, 0x042A, 0x042B, 0x042C, 0x042D, 0x042E, 0x042F,
  0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437, 0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
  0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447, 0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F,
];
