import 'package:flutter_test/flutter_test.dart';
import 'package:kapiras/store.dart';
import 'package:kapiras/subs_generator.dart';
import 'package:kapiras/videos.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements SubsGenerator {
  bool fail = false;

  @override
  Future<GeneratedSubs> generate(String videoId) async {
    if (fail) throw Exception('no');
    return GeneratedSubs(
      sr: 'WEBVTT\n\n00:00.000 --> 00:01.000\nZdravo',
      ru: '',
      dict: {
        'zdravo': ['привет', ''],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const v = Video(id: 'aaaaaaaaaaa', title: 'T', channel: 'C', mine: true);

  test('свой ролик и его субтитры сохраняются на устройстве', () async {
    SharedPreferences.setMockInitialValues({});
    final fake = subsGenerator = _Fake();
    final s = AppStore();
    await s.load();
    s.addVideo(v);
    expect(s.myVideo(v.id)!.status, SubsStatus.processing);
    await pumpEventQueue();
    expect(s.myVideo(v.id)!.status, SubsStatus.ready);

    final again = AppStore();
    await again.load();
    expect(again.myVideos.single.video.title, 'T');
    expect((await again.loadSubs(v))!.dict['zdravo'], ['привет', '']);

    fake.fail = true;
    await again.generateSubs(v.id);
    expect(again.myVideo(v.id)!.status, SubsStatus.failed);

    again.removeVideo(v.id);
    expect(again.myVideos, isEmpty);
    expect(await again.loadSubs(v), isNull);
  });

  test('parseVideoId', () {
    expect(parseVideoId('https://www.youtube.com/watch?v=dxE0__WvLBU&t=5'), 'dxE0__WvLBU');
    expect(parseVideoId('https://youtu.be/dxE0__WvLBU?si=x'), 'dxE0__WvLBU');
    expect(parseVideoId('dxE0__WvLBU'), 'dxE0__WvLBU');
    expect(parseVideoId('привет'), isNull);
  });

  test('сердечко ставится, снимается и сохраняется', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    s.toggleLike('a');
    s.toggleLike('b');
    s.toggleLike('a');
    expect(s.liked, ['b']);
    expect(s.isLiked('b'), true);
    expect(s.isLiked('a'), false);

    final again = AppStore();
    await again.load();
    expect(again.liked, ['b']);
  });

  test('история помнит открытые ролики, последний — в конце', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    s.markWatched('a');
    s.markWatched('b');
    s.markWatched('a');
    expect(s.history, ['b', 'a']);
    expect(s.isWatched('b'), true);
    expect(s.isWatched('c'), false);

    s.add(SavedWord(key: 'zdravo', tr: 'привет', ctx: '', t: 0, video: 'a'));
    expect(s.wordCount('a'), 1);
    expect(s.wordCount('b'), 0);

    final again = AppStore();
    await again.load();
    expect(again.history, ['b', 'a']);
  });

  test('место остановки сохраняется, у досмотренного ролика — сбрасывается', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    expect(s.positionOf('a'), isNull);
    s.setPosition('a', 42.5);
    s.setPosition('b', 7);
    s.setPosition('b', null);

    final again = AppStore();
    await again.load();
    expect(again.positionOf('a'), 42.5);
    expect(again.positionOf('b'), isNull);
  });

  test('шкала просмотра сохраняется, у старых роликов считается по месту остановки', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    const v = Video(id: 'a', title: '', channel: '', topic: '', duration: '1:40');
    expect(s.progressOf(v), 0);
    s.setPosition('a', 25);
    expect(s.progressOf(v), 0.25);
    s.setProgress('a', 1);

    final again = AppStore();
    await again.load();
    expect(again.progressOf(v), 1);
  });
}
