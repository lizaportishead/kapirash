import 'dart:async';

/// Результат генерации: субтитры в VTT и словарик ролика `{ "слово": ["перевод", "пометка"] }` —
/// в том же виде, что и у готовых роликов в assets.
class GeneratedSubs {
  const GeneratedSubs({required this.sr, required this.ru, required this.dict});
  final String sr, ru;
  final Map<String, dynamic> dict;
}

/// Система, которая распознаёт речь в ролике, переводит её и собирает словарик.
/// Результат отдаётся только этому устройству: приложение хранит его локально и никуда не отправляет.
abstract class SubsGenerator {
  Future<GeneratedSubs> generate(String videoId);
}

// Бэкенда пока нет — генерация замокана: ролик остаётся в состоянии «Готовим субтитры».
class _StubSubsGenerator implements SubsGenerator {
  @override
  Future<GeneratedSubs> generate(String videoId) => Completer<GeneratedSubs>().future;
}

SubsGenerator subsGenerator = _StubSubsGenerator();
