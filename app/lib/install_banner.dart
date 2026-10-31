import 'package:flutter/material.dart';
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
            child: Icon(_platform == 'ios' ? Icons.ios_share_rounded : Icons.add_to_home_screen_rounded, size: 24, color: cOnViolet),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500, color: cOnViolet)),
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
