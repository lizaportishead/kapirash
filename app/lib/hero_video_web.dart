import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Зацикленное беззвучное видео для хиро лендинга. Время отдаёт наружу, чтобы синхронизировать субтитры.
class HeroVideo extends StatefulWidget {
  const HeroVideo({super.key, required this.src, required this.onTime, this.seconds = 10});
  final String src;

  /// Крутим только первые [seconds] секунд ролика.
  final double seconds;
  final ValueChanged<double> onTime;

  @override
  State<HeroVideo> createState() => _HeroVideoState();
}

class _HeroVideoState extends State<HeroVideo> {
  static int _count = 0;
  final _type = 'hero-video-${_count++}';
  late final web.HTMLVideoElement _video;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _video = web.HTMLVideoElement()
      // Относительный адрес: работает и под base-href /kapirash/.
      ..src = widget.src
      ..muted = true
      ..autoplay = true
      // Чуть замедляем, чтобы субтитры успевали читаться.
      ..defaultPlaybackRate = 0.75
      ..playbackRate = 0.75
      ..playsInline = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.pointerEvents = 'none';
    ui_web.platformViewRegistry.registerViewFactory(_type, (int _) => _video);
    _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      if (_video.currentTime >= widget.seconds || _video.ended) _video.currentTime = 0;
      widget.onTime(_video.currentTime);
    });
    // Автоплей без звука разрешён; если браузер всё же откажет, видео просто останется на первом кадре.
    unawaited(_video.play().toDart.then((_) {}, onError: (_) {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _type);
}
