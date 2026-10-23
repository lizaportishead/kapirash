import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class PodAudio {
  final _el = web.HTMLAudioElement()..preload = 'auto';
  final _pos = StreamController<Duration>.broadcast();
  final _dur = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _done = StreamController<void>.broadcast();

  PodAudio() {
    web.EventStreamProviders.timeUpdateEvent.forTarget(_el).listen((_) => _pos.add(_ms(_el.currentTime)));
    web.EventStreamProviders.durationChangeEvent.forTarget(_el).listen((_) {
      if (_el.duration.isFinite) _dur.add(_ms(_el.duration));
    });
    web.EventStreamProviders.playEvent.forTarget(_el).listen((_) => _playing.add(true));
    web.EventStreamProviders.pauseEvent.forTarget(_el).listen((_) => _playing.add(false));
    web.EventStreamProviders.endedEvent.forTarget(_el).listen((_) {
      _playing.add(false);
      _done.add(null);
    });
  }

  static Duration _ms(num s) => Duration(milliseconds: (s * 1000).round());

  Stream<Duration> get onPosition => _pos.stream;
  Stream<Duration> get onDuration => _dur.stream;
  Stream<bool> get onPlaying => _playing.stream;
  Stream<void> get onComplete => _done.stream;

  Future<void> setSource(String url) async => _el.src = url;
  Future<void> play(String url, Duration position) async {
    if (_el.src != url) _el.src = url;
    if (position > Duration.zero) _el.currentTime = position.inMilliseconds / 1000;
    await _el.play().toDart;
  }

  Future<void> resume() async => _el.play().toDart;
  Future<void> pause() async => _el.pause();
  Future<void> seek(Duration d) async => _el.currentTime = d.inMilliseconds / 1000;
  Future<void> setRate(double r) async => _el.playbackRate = r;

  Future<void> dispose() async {
    _el.pause();
    _el.removeAttribute('src');
    _el.load();
    for (final c in [_pos, _dur, _playing, _done]) {
      await c.close();
    }
  }
}
