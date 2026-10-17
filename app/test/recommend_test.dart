import 'package:flutter_test/flutter_test.dart';
import 'package:kapiras/recommend.dart';
import 'package:kapiras/stories_page.dart';
import 'package:kapiras/videos.dart';

void main() {
  test('ранг уровня', () {
    expect(['A1', 'A2', 'B1', 'B2', 'C1', ''].map(levelRank), [1, 1, 2, 3, 3, 0]);
  });

  test('ролики: тема важнее соседнего уровня, слишком сложное — в конец', () {
    const a = Video(id: 'a', title: '', channel: '', topic: 'Еда', level: 'B1');
    const b = Video(id: 'b', title: '', channel: '', topic: 'Спорт', level: 'B1');
    const c = Video(id: 'c', title: '', channel: '', topic: 'Еда', level: 'B2');
    final r = recommendVideos([c, b, a], level: 'A', interests: ['Еда']);
    // a: уровень B1 на 1 выше A (0.5) + тема 3; c: 2 выше (-1) + тема 3; b: 0.5.
    expect(r.map((v) => v.id), ['a', 'c', 'b']);
  });

  test('без ответов остаётся порядок по популярности и ничего не падает', () {
    expect(recommendVideos(videos, limit: 3), hasLength(3));
  });

  test('рассказы: подходящий уровень первым, заглушки скрыты', () {
    final r = recommendStories(stories, level: 'B2');
    expect(r.first.level, 'B2');
    expect(r.every((s) => s.ready), isTrue);
  });
}
