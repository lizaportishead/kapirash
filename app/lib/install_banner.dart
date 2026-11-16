import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics.dart';
import 'install_io.dart' if (dart.library.js_interop) 'install_web.dart';
import 'l10n.dart';
import 'theme.dart';

/// События «добавил на экран Домой»: appinstalled (Android) и первый запуск из установленного приложения (iOS не шлёт appinstalled).
/// В iOS PWA своё хранилище, поэтому флаг «уже слали» живёт внутри самого приложения.
Future<void> trackHomeScreenInstall() async {
  onAppInstalled(() => trackEvent('added_to_home_screen', {'source': 'appinstalled'}));
  if (!isStandalone()) return;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('install_tracked') == true) return;
  await prefs.setBool('install_tracked', true);
  trackEvent('added_to_home_screen', {'source': 'first_standalone_launch'});
}

/// Подсказка в мобильном браузере: добавить сайт на экран «Домой». Закрывается крестиком насовсем.
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  static const _key = 'install_banner_dismissed';
  final String? _platform = installPlatform();
  bool _show = false;

  @override
  void initState() {
    super.initState();
    if (_platform != null) {
      SharedPreferences.getInstance().then((p) {
        if (mounted && p.getBool(_key) != true) setState(() => _show = true);
      });
    }
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    (await SharedPreferences.getInstance()).setBool(_key, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return SizedBox.shrink();
    final text = _platform == 'ios'
        ? ui('Добавь Капираш на экран «Домой»: нажми «Поделиться» и «На экран Домой»')
        : ui('Добавь Капираш на главный экран: меню браузера → «Установить приложение»');
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: EdgeInsets.fromLTRB(10, 10, 2, 10),
      decoration: BoxDecoration(
        color: cViolet,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Color(0x26FFFFFF), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              _platform == 'ios' ? Icons.ios_share_rounded : Icons.add_to_home_screen_rounded,
              size: 24,
              color: cOnViolet,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500, color: cOnViolet),
            ),
          ),
          IconButton(
            tooltip: ui('Закрыть'),
            onPressed: _dismiss,
            icon: Icon(Icons.close, size: 18, color: cOnViolet),
          ),
        ],
      ),
    );
  }
}

bool _landscapeDialogShown = false;

/// В горизонтальном положении в мобильном браузере: диалог «добавь на экран Домой, чтобы смотреть без интерфейса браузера».
/// Раз за сессию; «Больше не показывать» отключает насовсем.
Future<void> maybeShowLandscapeInstallDialog(BuildContext context) async {
  if (_landscapeDialogShown) return;
  final platform = installPlatform();
  if (platform == null) return;
  _landscapeDialogShown = true;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('install_landscape_dismissed') == true) return;
  if (!context.mounted) return;
  final never = await showDialog<bool>(
    context: context,
    // Видео YouTube — iframe и перехватывает клики под диалогом, поэтому оборачиваем в PointerInterceptor.
    builder: (ctx) => PointerInterceptor(
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(
              child: Text(ui('Смотри на весь экран'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: ui('Закрыть'),
              onPressed: () => Navigator.pop(ctx, false),
              icon: Icon(Icons.close, size: 22, color: cMuted),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ui('Чтобы смотреть видео без панелей браузера, добавьте приложение на экран «Домой»'),
                  style: TextStyle(fontSize: 14, height: 1.35),
                ),
                SizedBox(height: 12),
                _InstallSteps(platform),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ui('Больше не показывать'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cViolet, foregroundColor: cOnViolet),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ui('Понятно')),
          ),
        ],
      ),
    ),
  );
  if (never == true) await prefs.setBool('install_landscape_dismissed', true);
}

/// Иллюстрация: три шага, как добавить сайт на экран «Домой». Иконка слева, подпись справа.
class _InstallSteps extends StatelessWidget {
  const _InstallSteps(this.platform);
  final String platform;

  Widget _step(Widget icon, String label, {int flex = 4}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          icon,
          SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, height: 1.2, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _circle(IconData icon) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: cViolet.withValues(alpha: 0.14), shape: BoxShape.circle),
    child: Icon(icon, size: 20, color: cViolet),
  );

  Widget _arrow() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Icon(Icons.arrow_forward_rounded, size: 16, color: cFaint),
  );

  @override
  Widget build(BuildContext context) {
    final ios = platform == 'ios';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(color: Color(0xFFF4F2FF), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _step(
            _circle(ios ? Icons.ios_share_rounded : Icons.more_vert_rounded),
            ios ? ui('Поделиться') : ui('Меню браузера'),
          ),
          _arrow(),
          _step(
            _circle(ios ? Icons.add_box_outlined : Icons.add_to_home_screen_rounded),
            ios ? ui('На экран «Домой»') : ui('Установить приложение'),
          ),
          _arrow(),
          _step(
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset('assets/app_icon.png', width: 36, height: 36),
            ),
            ui('Иконка на экране «Домой»'),
            flex: 5,
          ),
        ],
      ),
    );
  }
}
