import 'package:flutter/material.dart';

import 'store.dart';
import 'l10n.dart';

const kFont = 'Montserrat';

// Цвета двух тем: светлая по умолчанию, тёмная включается в профиле.
Color _c(int light, int dark) => Color(store.dark ? dark : light);

Color get cBg => _c(0xFFF3F4F7, 0xFF0E0E12);
Color get cCard => _c(0xFFFFFFFF, 0xFF1A1A21);
Color get cCard2 => _c(0xFFE7E8EE, 0xFF272731);
Color get cLine => _c(0xFFE2E3EA, 0xFF30303B);
Color get cText => _c(0xFF111114, 0xFFF5F5F7);
Color get cMuted => _c(0xFF565862, 0xFFB4B5C0);
Color get cFaint => _c(0xFF6E707B, 0xFF8D8EA0);
// Пустая звёздочка в строках списков: светло-серая.
Color get cStarOff => _c(0xFFB7BAC5, 0xFF5E5F70);

/// Акцент как цвет текста: фиолетовый, в тёмной теме — светлее.
Color get cAccentText => _c(0xFF5A3FE0, 0xFFB5A6FF);

// Два цвета приложения, от темы не зависят: жёлтая заливка с тёмным текстом и фиолетовая — со светлым.
const cAccent = Color(0xFFE6EC68);
const cViolet = Color(0xFF7357F6);
const cOnViolet = Color(0xFFFFFFFF);
const cInk = Color(0xFF111114);
const cOnInk = Color(0xFFFFFFFF);

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.on = false,
    this.label,
    this.icon,
    this.badge = 0,
    this.onColor,
    required this.onTap,
  });
  final String text;

  /// Фон выбранной пилюли вместо стандартного; текст на нём тёмный.
  final Color? onColor;
  final int badge;
  final IconData? icon;
  final String? label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: on ? (onColor ?? cText) : cCard2,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 38,
            constraints: BoxConstraints(minWidth: 42),
            padding: EdgeInsets.symmetric(horizontal: 14),
            // Центр по ширине содержимого: Container с alignment растянулся бы на всю строку Wrap.
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Без текста — кнопка-иконка, значок крупнее.
                  if (icon != null)
                    Icon(icon, size: text.isEmpty ? 24 : 16, color: on ? (onColor != null ? cInk : cBg) : cText),
                  if (icon != null && text.isNotEmpty) SizedBox(width: 6),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: on ? (onColor != null ? cInk : cBg) : cText,
                      ),
                    ),
                  if (badge > 0) ...[
                    SizedBox(width: 6),
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: cViolet, shape: BoxShape.circle),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$badge',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Главная кнопка экрана: чёрная «таблетка» во всю ширину. Цвета можно задать для цветного фона.
class BigButton extends StatelessWidget {
  const BigButton(this.text, {super.key, required this.onTap, this.bg, this.fg, this.compact = false});
  final String text;
  // Невысокая кнопка для плавающих карточек на десктопе.
  final bool compact;
  final VoidCallback? onTap;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    // Главная кнопка экрана всегда фиолетовая; другие цвета — только для второстепенных.
    final bg = this.bg ?? cViolet, fg = this.fg ?? cOnViolet;
    return SizedBox(
      height: compact ? 44 : 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          disabledForegroundColor: fg,
          shape: StadiumBorder(),
          textStyle: TextStyle(fontFamily: kFont, fontSize: compact ? 15 : 16, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false)),
      ),
    );
  }
}

/// Крупный заголовок; слова между звёздочками подсвечены плашкой.
class Headline extends StatelessWidget {
  const Headline(
    this.text, {
    super.key,
    required this.color,
    required this.mark,
    this.onMark = cInk,
    this.maxSize = 60,
  });
  final String text;
  final Color color, mark, onMark;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: text.replaceAll('*', ''),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (_, box) {
            final size = (box.maxWidth / 7.4).clamp(28.0, maxSize);
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
            // Неразрывный пробел (\u00A0) склеивает соседние слова: вместе переносятся и вместе ужимаются.
            final groups = <List<Widget>>[];
            var glue = false;
            void add(Widget w) {
              if (glue && groups.isNotEmpty) {
                groups.last.add(w);
              } else {
                groups.add([w]);
              }
              glue = false;
            }

            for (var i = 0; i < parts.length; i++) {
              if (i.isOdd) {
                add(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.2),
                    decoration: BoxDecoration(color: mark, borderRadius: BorderRadius.circular(size * 0.36)),
                    child: Text(parts[i], style: style.copyWith(color: onMark)),
                  ),
                );
              } else {
                if (parts[i].startsWith('\u00A0')) glue = true;
                for (final w in parts[i].split(' ')) {
                  if (w.trim().isNotEmpty) add(Text(w.trim(), style: style));
                }
                if (parts[i].endsWith('\u00A0')) glue = true;
              }
            }
            return Wrap(
              spacing: size * 0.26,
              runSpacing: size * 0.04,
              children: [
                for (final g in groups)
                  fit(
                    g.length == 1 ? g.single : Row(mainAxisSize: MainAxisSize.min, spacing: size * 0.26, children: g),
                  ),
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

/// Высота верхней полосы: у логотипа в боковой панели и у шапки страницы справа она одинаковая.
const double kTopBarHeight = 64;

/// Заголовок экрана в табе; справа можно положить кнопки.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.actions = const [], this.icon, this.back = false});
  final String text;
  final IconData? icon;
  final List<Widget> actions;

  /// Стрелка «назад» в той же строке, что и заголовок (для экранов, открытых поверх таббара).
  final bool back;

  @override
  Widget build(BuildContext context) {
    return HeaderAnchor(
      child: Container(
        constraints: BoxConstraints(minHeight: kTopBarHeight),
        padding: EdgeInsets.fromLTRB(back ? 12 : 16, 8, 12, 8),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            if (back)
              IconButton(
                tooltip: ui('Назад'),
                icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
                onPressed: () => Navigator.pop(context),
              ),
            if (icon != null) ...[Icon(icon, size: 28, color: cViolet), SizedBox(width: 10)],
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
      ),
    );
  }
}

/// Сложность по уровню (A1–C2): подпись и цвет кружка.
(String, Color)? difficultyOf(String level) {
  final l = level.toUpperCase();
  if (l.startsWith('A')) return (ui('Простое'), Color(0xFF34A853));
  if (l == 'B1') return (ui('Среднее'), Color(0xFFF59E0B));
  if (l.startsWith('B')) return (ui('Сложное'), Color(0xFFE53935));
  if (l.startsWith('C')) return (ui('Очень сложное'), Color(0xFF8E24AA));
  return null;
}

class DifficultyLabel extends StatelessWidget {
  const DifficultyLabel(this.level, {super.key, this.size = 13, this.color});
  final String level;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final d = difficultyOf(level);
    if (d == null) return SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: d.$2),
        SizedBox(width: 5),
        Text(
          d.$1,
          style: TextStyle(fontSize: size, color: color ?? cMuted),
        ),
      ],
    );
  }
}

/// Шапка страницы второго уровня: на десктопе «назад» и заголовок в одной строке, на телефоне — отдельная полоса сверху.
List<Widget> pageHeader(BuildContext context, String text, {IconData? icon}) => MediaQuery.sizeOf(context).width >= 600
    ? [PageTitle(text, icon: icon, back: true)]
    : [BackBar(), PageTitle(text, icon: icon)];

/// Шапка страницы второго уровня: кнопка «Назад» у левого края на всю ширину экрана.
class BackBar extends StatelessWidget {
  const BackBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kTopBarHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 12),
          child: IconButton(
            tooltip: ui('Назад'),
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

/// Белая плашка: в покое — лёгкая тень, при наведении поднимается и даёт большую фиолетовую тень.
class Lift extends StatefulWidget {
  const Lift({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<Lift> createState() => _LiftState();
}

class _LiftState extends State<Lift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final up = _hover;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, up ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            up
                ? BoxShadow(color: cViolet.withValues(alpha: 0.25), blurRadius: 10, offset: Offset(0, 3))
                : BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: HoverInfo(hovered: up, child: widget.child),
      ),
    );
  }
}

/// Говорит потомкам, наведён ли курсор на карточку.
class HoverInfo extends InheritedWidget {
  const HoverInfo({super.key, required this.hovered, required super.child});
  final bool hovered;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<HoverInfo>()?.hovered ?? false;

  @override
  bool updateShouldNotify(HoverInfo old) => hovered != old.hovered;
}

/// Шапка страницы: когда список под ней прокручен, снизу появляется тень.
/// Какая шапка принадлежит какому списку, узнаём по ближайшему общему предку (см. [HeaderShadow.handle]).
class HeaderAnchor extends StatefulWidget {
  const HeaderAnchor({super.key, required this.child});
  final Widget child;

  @override
  State<HeaderAnchor> createState() => _HeaderAnchorState();
}

class _HeaderAnchorState extends State<HeaderAnchor> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final scrolled = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    HeaderShadow._anchors.add(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  void dispose() {
    HeaderShadow._anchors.remove(this);
    scrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) => CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (ctx) => CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            showWhenUnlinked: false,
            child: IgnorePointer(
              child: SizedBox(
                width: box.maxWidth,
                height: 10,
                child: ValueListenableBuilder(
                  valueListenable: scrolled,
                  builder: (_, on, _) => AnimatedOpacity(
                    duration: Duration(milliseconds: 150),
                    // Скрытая вкладка не должна показывать тень поверх соседней.
                    opacity: on && TickerMode.of(ctx) ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x1A000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class HeaderShadow {
  static final _anchors = <_HeaderAnchorState>{};
  static final _owner = Expando<_HeaderAnchorState>();

  /// Слушатель прокрутки на уровне приложения: включает тень у шапки той же страницы.
  static bool handle(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final ctx = n.context;
    if (ctx == null) return false;
    var anchor = _owner[ctx];
    if (anchor == null || !anchor.mounted) {
      anchor = _find(ctx);
      _owner[ctx] = anchor;
    }
    anchor?.scrolled.value = n.metrics.pixels > 1;
    return false;
  }

  // Ближайший предок списка, внутри которого есть шапка, — это страница; её шапка и нужна.
  static _HeaderAnchorState? _find(BuildContext ctx) {
    _HeaderAnchorState? found;
    ctx.visitAncestorElements((a) {
      for (final h in _anchors) {
        var inside = false;
        h.context.visitAncestorElements((x) {
          if (identical(x, a)) {
            inside = true;
            return false;
          }
          return true;
        });
        if (inside) {
          found = h;
          return false;
        }
      }
      return true;
    });
    return found;
  }
}
