import 'stories_page.dart';
import 'store.dart';
import 'videos.dart';

/// Уровень анкеты: 'A' (A2 — начинаем с него, A1 не предлагаем), 'B1' или 'B2' (B2 и выше).
const surveyLevels = ['A', 'B1', 'B2'];

/// Ранг уровня для сравнения: 1 — A1–A2, 2 — B1, 3 — B2 и выше; 0 — уровень неизвестен.
int levelRank(String level) {
  final l = level.toUpperCase();
  if (l.isEmpty) return 0;
  if (l.startsWith('A')) return 1;
  return l == 'B1' ? 2 : 3;
}

/// Подпись уровня из анкеты: «A2», «B1», «B2+».
String levelLabel(String level) => switch (level) {
  'A' => 'A2',
  'B2' => 'B2+',
  _ => level,
};

/// Насколько уровень материала подходит уровню человека. Чуть проще — почти так же хорошо, как в точку;
/// сложнее — хуже, потому что смотреть такое тяжело.
double _levelScore(String itemLevel, String? me) {
  final a = levelRank(itemLevel), b = me == null ? 0 : levelRank(me);
  if (a == 0 || b == 0) return 0;
  return switch (a - b) {
    0 => 3,
    -1 => 2,
    1 => 0.5,
    _ => -1,
  };
}

/// Ролики, которые стоит показать этому человеку: сначала по уровню и темам, непросмотренные выше просмотренных,
/// при равных баллах — популярные. Без ответов анкеты получается просто «популярное».
List<Video> recommendVideos(List<Video> list, {String? level, List<String> interests = const [], int limit = 8}) {
  double score(Video v) =>
      _levelScore(v.level, level) + (interests.contains(v.topic) ? 3 : 0) - (store.isWatched(v.id) ? 4 : 0);
  final sorted = [...list]
    ..sort((a, b) {
      final d = score(b).compareTo(score(a));
      return d != 0 ? d : b.views.compareTo(a.views);
    });
  return sorted.take(limit).toList();
}

/// Готовые рассказы по уровню: подходящие первыми, остальные — по близости к нему.
List<Story> recommendStories(List<Story> list, {String? level}) {
  final ready = [
    for (final s in list)
      if (s.ready) s,
  ];
  // sort стабилен, поэтому при равных баллах порядок каталога сохраняется.
  ready.sort((a, b) => _levelScore(b.level, level).compareTo(_levelScore(a.level, level)));
  return ready;
}

/// Темы каталога, самые частые первыми.
List<String> catalogTopics() {
  final count = <String, int>{};
  for (final v in videos.followedBy(clips)) {
    if (v.topic.isNotEmpty) count[v.topic] = (count[v.topic] ?? 0) + 1;
  }
  return count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
}
