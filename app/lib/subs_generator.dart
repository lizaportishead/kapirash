import 'dart:convert';

import 'store.dart';
import 'videos.dart';
import 'l10n.dart';

/// Результат генерации: субтитры в VTT и словарик ролика `{ "слово": ["перевод", "пометка"] }` —
/// в том же виде, что и у готовых роликов в assets.
class GeneratedSubs {
  const GeneratedSubs({required this.sr, required this.ru, required this.dict});
  final String sr, ru;
  final Map<String, dynamic> dict;
}

/// Система, которая распознаёт речь в ролике, переводит её и собирает словарик.
abstract class SubsGenerator {
  Future<GeneratedSubs> generate(Video video, {bool retry = false});
}

/// Очередь в Supabase: ставим заявку в `video_requests`, воркер в GitHub Actions (tools/worker) готовит субтитры
/// и кладёт их в бакет `subs`; мы ждём, пока заявка станет `ready`, и забираем файлы.
class _QueueSubsGenerator implements SubsGenerator {
  @override
  Future<GeneratedSubs> generate(Video video, {bool retry = false}) async {
    final db = cloud;
    if (db == null) throw StateError(ui('Нет связи с облаком'));
    final table = db.from('video_requests');
    final row = await table.select('status').eq('id', video.id).maybeSingle();
    if (row == null) {
      await table.insert({'id': video.id, 'title': video.title, 'channel': video.channel});
    } else if (retry && row['status'] == 'failed') {
      await table.update({'status': 'queued', 'error': null, 'finished_at': null}).eq('id', video.id);
    }
    while (true) {
      // Ролик удалили, пока ждали.
      if (store.myVideo(video.id) == null) throw StateError(ui('Ролик удалён'));
      final r = await table.select('status, error').eq('id', video.id).maybeSingle();
      if (r == null) throw StateError(ui('Заявка пропала'));
      if (r['status'] == 'failed') throw StateError(r['error'] ?? ui('Не получилось'));
      if (r['status'] == 'ready') break;
      await Future<void>.delayed(Duration(seconds: 15));
    }
    final files = db.storage.from('subs');
    Future<String> text(String ext) async => utf8.decode(await files.download('${video.id}.$ext'));
    return GeneratedSubs(
      sr: await text('sr.vtt'),
      ru: await text('ru.vtt'),
      dict: jsonDecode(await text('dict.json')) as Map<String, dynamic>,
    );
  }
}

SubsGenerator subsGenerator = _QueueSubsGenerator();
