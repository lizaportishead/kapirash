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
}
