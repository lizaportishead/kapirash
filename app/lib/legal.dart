import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n.dart';
import 'theme.dart';

const _site = 'https://kapiras.app';

Future<void> openPrivacy() => launchUrl(Uri.parse('$_site/privacy.html?lang=$uiLang'), mode: LaunchMode.externalApplication);

Future<void> openTerms() => launchUrl(Uri.parse('$_site/terms.html?lang=$uiLang'), mode: LaunchMode.externalApplication);

/// Строка под кнопками входа: вход означает согласие с условиями и политикой.
class LegalLine extends StatelessWidget {
  const LegalLine({super.key});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 12, height: 1.4, color: cMuted);
    final link = base.copyWith(decoration: TextDecoration.underline);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${ui('Входя, ты принимаешь')} ', style: base),
        GestureDetector(onTap: openTerms, child: Text(ui('Условия'), style: link)),
        Text(' ${ui('и')} ', style: base),
        GestureDetector(onTap: openPrivacy, child: Text(ui('Политику конфиденциальности'), style: link)),
      ],
    );
  }
}
