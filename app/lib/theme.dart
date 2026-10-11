import 'package:flutter/material.dart';

import 'store.dart';

const kFont = 'Montserrat';

// Цвета двух тем: светлая по умолчанию, тёмная включается в профиле.
Color _c(int light, int dark) => Color(store.dark ? dark : light);

Color get cBg => _c(0xFFFFFFFF, 0xFF0E0E12);
Color get cCard => _c(0xFFF3F4F7, 0xFF1A1A21);
Color get cCard2 => _c(0xFFE7E8EE, 0xFF272731);
Color get cLine => _c(0xFFE2E3EA, 0xFF30303B);
Color get cText => _c(0xFF111114, 0xFFF5F5F7);
Color get cMuted => _c(0xFF565862, 0xFFB4B5C0);
Color get cFaint => _c(0xFF6E707B, 0xFF8D8EA0);

/// Акцент как цвет текста: фиолетовый, в тёмной теме — светлее.
Color get cAccentText => _c(0xFF5A3FE0, 0xFFB5A6FF);

// Два цвета приложения, от темы не зависят: жёлтая заливка с тёмным текстом и фиолетовая — со светлым.
const cAccent = Color(0xFFE6EC68);
const cViolet = Color(0xFF7357F6);
const cOnViolet = Color(0xFFFFFFFF);
const cInk = Color(0xFF111114);
const cOnInk = Color(0xFFFFFFFF);

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.on = false, this.label, required this.onTap});
  final String text;
  final String? label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: on ? cText : cCard2,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 38,
            constraints: BoxConstraints(minWidth: 42),
            padding: EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? cBg : cText),
            ),
          ),
        ),
      ),
    );
  }
}

/// Главная кнопка экрана: чёрная «таблетка» во всю ширину. Цвета можно задать для цветного фона.
class BigButton extends StatelessWidget {
  const BigButton(this.text, {super.key, required this.onTap, this.bg, this.fg});
  final String text;
  final VoidCallback? onTap;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    final bg = this.bg ?? cText, fg = this.fg ?? cBg;
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg,
          shape: StadiumBorder(),
          textStyle: TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}

/// Крупный заголовок капсом; слова между звёздочками подсвечены плашкой.
class Headline extends StatelessWidget {
  const Headline(this.text, {super.key, required this.color, required this.mark, this.onMark = cInk});
  final String text;
  final Color color, mark, onMark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: text.replaceAll('*', ''),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (_, box) {
            final size = (box.maxWidth / 7.4).clamp(28.0, 60.0);
            final style = TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -size * 0.02,
              color: color,
            );
            // Слово длиннее строки не переносится, а ужимается.
            Widget fit(Widget w) => ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth),
              child: FittedBox(fit: BoxFit.scaleDown, child: w),
            );
            final parts = text.split('*');
            return Wrap(
              spacing: size * 0.26,
              runSpacing: size * 0.04,
              children: [
                for (var i = 0; i < parts.length; i++)
                  if (i.isOdd)
                    fit(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: size * 0.2),
                        decoration: BoxDecoration(color: mark, borderRadius: BorderRadius.circular(size * 0.36)),
                        child: Text(parts[i], style: style.copyWith(color: onMark)),
                      ),
                    )
                  else
                    for (final w in parts[i].split(' '))
                      if (w.isNotEmpty) fit(Text(w, style: style)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Цветная плашка-наклейка, слегка повёрнутая.
class Sticker extends StatelessWidget {
  const Sticker(this.text, {super.key, required this.color, this.fg = cInk, this.angle = 0, this.round = true});
  final String text;
  final Color color, fg;
  final double angle;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(round ? 999 : 14)),
        child: Text(
          text,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.2, color: fg),
        ),
      ),
    );
  }
}

/// Заголовок экрана в табе; справа можно положить кнопки.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.actions = const []});
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: cText),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
