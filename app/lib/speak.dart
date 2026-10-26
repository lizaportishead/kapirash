import 'package:audioplayers/audioplayers.dart';

import 'speak_io.dart' if (dart.library.js_interop) 'speak_web.dart';
import 'subs.dart';
import 'supabase_config.dart';

final _player = AudioPlayer();

const _fold = {'č': '_c', 'ć': '_k', 'š': '_s', 'ž': '_z', 'đ': '_d'};

/// Имя файла озвучки слова в бакете tts; то же правило, что `word_file` в tools/word_audio.py.
String? _file(String word) {
  final out = toLat(word).toLowerCase().split('').map((c) => _fold[c] ?? c).join();
  return RegExp(r'^[a-z_]+$').hasMatch(out) ? '$out.mp3' : null;
}

/// Озвучивает слово заранее записанным сербским голосом; если записи нет — системным голосом.
Future<void> speakWord(String word) async {
  final file = _file(word);
  if (file != null) {
    try {
      await _player.stop();
      await _player.play(UrlSource('$supabaseUrl/storage/v1/object/public/tts/$file')).timeout(Duration(seconds: 4));
      return;
    } catch (_) {}
  }
  await speakWordSystem(toCyr(toLat(word)));
}
