import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapiras/story_import.dart';

void main() {
  test('кириллица становится латиницей, абзацы сохраняются', () {
    final t = prepareText('Љубав и Његош.\n\nЂак у џепу.');
    expect(t.text, 'Ljubav i Njegoš.\n\nĐak u džepu.');
  });

  test('лимит по страницам обрезает по абзацу', () {
    final para = 'a' * 1000;
    final t = prepareText(List.filled(300, para).join('\n\n'));
    expect(t.cut, isTrue);
    expect(t.text.length, lessThanOrEqualTo(kStoryMaxChars));
  });

  test('fb2', () {
    const x = '<?xml version="1.0" encoding="utf-8"?><FictionBook><description><title-info>'
        '<author><first-name>Иво</first-name><last-name>Андрић</last-name></author>'
        '<book-title>На Дрини ћуприја</book-title></title-info></description>'
        '<body><section><p>Прва реченица.</p><p>Друга.</p></section></body></FictionBook>';
    final t = importFile('a.fb2', Uint8List.fromList(utf8.encode(x)));
    expect(t.title, 'Na Drini ćuprija');
    expect(t.author, 'Ivo Andrić');
    expect(t.text, 'Prva rečenica.\n\nDruga.');
  });

  test('docx', () {
    const doc = '<w:document xmlns:w="w"><w:body><w:p><w:r><w:t>Zdravo</w:t></w:r></w:p>'
        '<w:p><w:r><w:t>svete</w:t></w:r></w:p></w:body></w:document>';
    final a = Archive()..addFile(ArchiveFile.bytes('word/document.xml', utf8.encode(doc)));
    final t = importFile('a.docx', Uint8List.fromList(ZipEncoder().encodeBytes(a)));
    expect(t.text, 'Zdravo\n\nsvete');
  });

  test('windows-1251', () {
    // «Ђак» в cp1251: 0x80 0xE0 0xEA
    final t = importFile('a.txt', Uint8List.fromList([0x80, 0xE0, 0xEA]));
    expect(t.text, 'Đak');
  });
}
