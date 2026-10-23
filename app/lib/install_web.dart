import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// 'ios' или 'android', если сайт открыт в мобильном браузере (не установлен как приложение), иначе null.
String? installPlatform() {
  // navigator.standalone есть только в iOS Safari, в типах package:web его нет.
  final iosStandalone = web.window.navigator.getProperty('standalone'.toJS);
  final standalone = web.window.matchMedia('(display-mode: standalone)').matches || iosStandalone.dartify() == true;
  if (standalone) return null;
  final ua = web.window.navigator.userAgent;
  if (RegExp(r'iPhone|iPad|iPod').hasMatch(ua)) return 'ios';
  if (ua.contains('Android')) return 'android';
  return null;
}
