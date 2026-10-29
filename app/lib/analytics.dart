import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Project API Key из PostHog → Project settings. Он публичный, его можно коммитить.
/// Пока ключ пустой, аналитика выключена. Для веба тот же ключ нужно вписать в web/index.html.
const posthogKey = 'phc_BHCkyZYubFM37ZGyMCj6UfFc3icjaQRYngossZguQ8b3';
const posthogHost = 'https://eu.i.posthog.com';

bool get analyticsOn => posthogKey.isNotEmpty;

Future<void> initAnalytics() async {
  // На вебе posthog-js поднимается из index.html, Dart-часть только шлёт события.
  if (!analyticsOn || kIsWeb) return;
  final config = PostHogConfig(posthogKey)
    ..host = posthogHost
    ..captureApplicationLifecycleEvents = true;
  await Posthog().setup(config);
}

/// Экраны второго уровня ловит observer по именам маршрутов (RouteSettings.name).
List<NavigatorObserver> analyticsObservers() => [if (analyticsOn) PosthogObserver()];

/// Вкладки нижнего меню переключаются без маршрутов, поэтому шлём их вручную.
void trackScreen(String name) {
  if (analyticsOn) Posthog().screen(screenName: name);
}

void trackEvent(String name, [Map<String, Object>? props]) {
  if (analyticsOn) Posthog().capture(eventName: name, properties: props);
}

/// Только id пользователя из Supabase, без почты и имени.
void identifyUser(String? id) {
  if (!analyticsOn) return;
  if (id == null) {
    Posthog().reset();
  } else {
    Posthog().identify(userId: id);
  }
}
