import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Сайт открыт как установленное приложение (с экрана «Домой»).
bool isStandalone() {
  // navigator.standalone есть только в iOS Safari, в типах package:web его нет.
  final iosStandalone = web.window.navigator.getProperty('standalone'.toJS);
  return web.window.matchMedia('(display-mode: standalone)').matches || iosStandalone.dartify() == true;
}

/// Android/Chrome сообщает об установке событием appinstalled; в iOS Safari такого события нет.
void onAppInstalled(void Function() cb) {
  web.window.addEventListener('appinstalled', ((web.Event _) => cb()).toJS);
}

/// 'ios' или 'android', если сайт открыт в мобильном браузере (не установлен как приложение), иначе null.
String? installPlatform() {
  if (isStandalone()) return null;
  final ua = web.window.navigator.userAgent;
  if (RegExp(r'iPhone|iPad|iPod').hasMatch(ua)) return 'ios';
  if (ua.contains('Android')) return 'android';
  return null;
}

/// Нижний отступ под индикатор «домой» на iPhone в PWA: Flutter web его не отдаёт, берём из CSS env().
double webSafeBottom() {
  final probe = web.document.createElement('div') as web.HTMLElement;
  probe.style.cssText = 'position:fixed;left:0;bottom:0;width:0;height:env(safe-area-inset-bottom,0px);visibility:hidden;pointer-events:none';
  web.document.body!.append(probe);
  final h = probe.getBoundingClientRect().height;
  probe.remove();
  if (h > 0) return h;
  // iOS мог закэшировать старый index.html без viewport-fit=cover, тогда env() даёт 0; в PWA на iPhone с индикатором это 34.
  final iosStandalone = web.window.navigator.getProperty('standalone'.toJS).dartify() == true;
  final iphone = web.window.navigator.userAgent.contains('iPhone') && web.window.screen.height >= 780;
  return iosStandalone && iphone ? 34 : 0;
}
