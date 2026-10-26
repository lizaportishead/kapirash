import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Адрес экрана для ссылок: `/video/ID`, `/podcast/ID`, `/story/ID`, `/feed`, `/words`.
/// Маршруты по-прежнему называются по экрану (для аналитики), а адрес лежит в arguments.
class UrlPath {
  const UrlPath(this.path);
  final String path;
}

RouteSettings urlSettings(String name, String path) => RouteSettings(name: name, arguments: UrlPath(path));

/// Ссылка, с которой открыли веб; ждёт, пока пользователь пройдёт онбординг и попадёт на главную оболочку.
String? pendingLink;

void captureInitialLink() {
  if (!kIsWeb) return;
  final name = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  pendingLink = name == '/' || name.isEmpty ? null : name;
}

/// Держит адрес в строке браузера: открытый экран второго уровня или адрес вкладки под ним.
/// Навигатор сам пишет в адрес имя маршрута, поэтому мы перезаписываем его после кадра.
class UrlSync {
  static final root = _UrlObserver();
  static final nested = _UrlObserver();

  /// Адрес текущей вкладки; null — главная оболочка не показана, адрес не трогаем (онбординг, вход).
  static String? _tabPath;
  static bool _scheduled = false;

  static void setTab(String? path) {
    _tabPath = path;
    schedule();
  }

  static void schedule() {
    if (!kIsWeb || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final base = _tabPath;
      if (base == null) return;
      final path = root.topPath ?? nested.topPath ?? base;
      SystemNavigator.routeInformationUpdated(uri: Uri.parse(path), replace: true);
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}

class _UrlObserver extends NavigatorObserver {
  final _stack = <Route<dynamic>>[];

  String? get topPath {
    for (final r in _stack.reversed) {
      final a = r.settings.arguments;
      if (a is UrlPath) return a.path;
    }
    return null;
  }

  void clear() => _stack.clear();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Первый маршрут нового навигатора: прежний стек остался от уничтоженного.
    if (previousRoute == null) _stack.clear();
    _stack.add(route);
    UrlSync.schedule();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    UrlSync.schedule();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    UrlSync.schedule();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute == null) {
        _stack.removeAt(i);
      } else {
        _stack[i] = newRoute;
      }
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    UrlSync.schedule();
  }
}
