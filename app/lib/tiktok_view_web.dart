import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Плеер TikTok в вебе: iframe, с которым переговариваемся через postMessage.
class TikTokView extends StatefulWidget {
  const TikTokView({super.key, required this.src, required this.onMessage, required this.bind});
  final String src;
  final void Function(Map<String, dynamic> message) onMessage;

  /// Отдаёт наружу функцию, которой плееру шлют команды.
  final void Function(void Function(String type, Object? value) send) bind;

  @override
  State<TikTokView> createState() => _TikTokViewState();
}

class _TikTokViewState extends State<TikTokView> {
  static int _count = 0;
  final _type = 'tiktok-${_count++}';
  late final web.HTMLIFrameElement _frame;
  late final JSFunction _listener;

  @override
  void initState() {
    super.initState();
    _frame = web.HTMLIFrameElement()
      ..src = widget.src
      ..allow = 'autoplay; encrypted-media'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      // Нажатия и свайпы забирает Flutter, иначе iframe съел бы их.
      ..style.pointerEvents = 'none';
    ui_web.platformViewRegistry.registerViewFactory(_type, (int _) => _frame);
    _listener = ((web.MessageEvent e) {
      final data = e.data.dartify();
      if (data is Map && data['x-tiktok-player'] == true) widget.onMessage(data.cast<String, dynamic>());
    }).toJS;
    web.window.addEventListener('message', _listener);
    widget.bind(
      (type, value) =>
          _frame.contentWindow?.postMessage({'type': type, 'value': ?value, 'x-tiktok-player': true}.jsify(), '*'.toJS),
    );
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _type);
}
