import 'package:audioplayers/audioplayers.dart';

class PodAudio {
  final _p = AudioPlayer();

  Stream<Duration> get onPosition => _p.onPositionChanged;
  Stream<Duration> get onDuration => _p.onDurationChanged;
  Stream<bool> get onPlaying => _p.onPlayerStateChanged.map((s) => s == PlayerState.playing);
  Stream<void> get onComplete => _p.onPlayerComplete;

  Future<void> setSource(String url) => _p.setSourceUrl(url);
  Future<void> play(String url, Duration position) => _p.play(UrlSource(url), position: position);
  Future<void> resume() => _p.resume();
  Future<void> pause() => _p.pause();
  Future<void> seek(Duration d) => _p.seek(d);
  Future<void> setRate(double r) => _p.setPlaybackRate(r);
  Future<void> dispose() => _p.dispose();
}
