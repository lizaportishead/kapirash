import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Плеер TikTok на телефоне: WebView со страницей-обёрткой, которая держит iframe плеера
/// и пересылает его сообщения в приложение.
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
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    _web =
        WebViewController.fromPlatformCreationParams(
            // Без этого iOS открывает видео на весь экран и не даёт запустить его без нажатия.
            WebViewPlatform.instance is WebKitWebViewPlatform
                ? WebKitWebViewControllerCreationParams(
                    allowsInlineMediaPlayback: true,
                    mediaTypesRequiringUserAction: const {},
                  )
                : const PlatformWebViewControllerCreationParams(),
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..addJavaScriptChannel(
            'Kapiras',
            onMessageReceived: (m) => widget.onMessage(jsonDecode(m.message) as Map<String, dynamic>),
          )
          ..loadHtmlString('''
<!doctype html>
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<style>html, body, iframe { margin: 0; width: 100%; height: 100%; border: 0; background: #000; overflow: hidden }</style>
<iframe id="player" src="${widget.src}" allow="autoplay; encrypted-media"></iframe>
<script>
  addEventListener('message', (e) => {
    if (e.data && e.data['x-tiktok-player']) Kapiras.postMessage(JSON.stringify(e.data));
  });
  function send(type, value) {
    document.getElementById('player').contentWindow.postMessage({type, value, 'x-tiktok-player': true}, '*');
  }
</script>
''', baseUrl: 'https://www.tiktok.com');
    widget.bind((type, value) => _web.runJavaScript('send(${jsonEncode(type)}, ${jsonEncode(value)})'));
  }

  @override
  Widget build(BuildContext context) {
    // Нажатия и свайпы обрабатывает экран с плеером, до WebView они не доходят.
    return IgnorePointer(child: WebViewWidget(controller: _web));
  }
}
