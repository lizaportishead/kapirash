import 'dart:async';

import 'package:flutter/widgets.dart';

import 'tiktok_view_io.dart' if (dart.library.js_interop) 'tiktok_view_web.dart';

/// Пульт встроенного плеера TikTok: где сейчас ролик, играет ли он, и команды ему.
class TikTokController {
  /// Секунда ролика. Плеер сообщает её редко, поэтому между сообщениями досчитываем сами —
  /// иначе субтитры отставали бы от речи.
  final time = ValueNotifier<double>(0);
  final playing = ValueNotifier<bool>(false);

  void Function(String type, Object? value)? _send;
  Timer? _tick;
  double _base = 0;
  DateTime _at = DateTime.now();
  bool _disposed = false;
  bool _unmuted = false;

  // Автозапуск у плеера беззвучный, поэтому звук включаем сами при каждом запуске.
  void play() {
    _send?.call('unMute', null);
    _send?.call('play', null);
  }

  void pause() => _send?.call('pause', null);
  void toggle() => playing.value ? pause() : play();

  void seek(double t) {
    _send?.call('seekTo', t);
    _set(t);
    play();
  }

  void _set(double t) {
    _base = t;
    _at = DateTime.now();
    time.value = t;
  }

  void _onMessage(Map<String, dynamic> m) {
    // Убранный с экрана плеер успевает прислать ещё пару сообщений.
    if (_disposed) return;
    final value = m['value'];
    switch (m['type']) {
      case 'onPlayerReady':
        _send?.call('unMute', null);
      case 'onCurrentTime' when value is Map:
        _set((value['currentTime'] as num).toDouble());
      case 'onStateChange':
        playing.value = value == 1;
        if (playing.value && !_unmuted) {
          _unmuted = true;
          _send?.call('unMute', null);
        }
        _tick?.cancel();
        _at = DateTime.now();
        if (playing.value) {
          _tick = Timer.periodic(Duration(milliseconds: 100), (_) {
            time.value = _base + DateTime.now().difference(_at).inMilliseconds / 1000;
          });
        }
    }
  }

  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _send = null;
    time.dispose();
    playing.dispose();
  }
}

/// Ролик TikTok в их встроенном плеере, без его собственных кнопок: управляем через [TikTokController].
/// Нажатия до плеера не доходят — их обрабатывает экран, на котором он стоит.
class TikTokPlayer extends StatelessWidget {
  const TikTokPlayer({super.key, required this.id, required this.controller});
  final String id;
  final TikTokController controller;

  @override
  Widget build(BuildContext context) {
    return TikTokView(
      src:
          'https://www.tiktok.com/player/v1/$id?autoplay=1&loop=1&controls=0&progress_bar=0&play_button=0'
          '&volume_control=0&fullscreen_button=0&timestamp=0&music_info=0&description=0&rel=0'
          '&native_context_menu=0&closed_caption=0',
      onMessage: controller._onMessage,
      bind: (send) => controller._send = send,
    );
  }
}
