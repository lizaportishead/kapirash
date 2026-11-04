import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'icons.dart';
import 'l10n.dart';
import 'stories_page.dart' show storyById;
import 'store.dart';
import 'theme.dart';
import 'videos.dart';

/// Что считает бейдж на иконке «Избранное».
enum FavScope { all, videos, podcasts, stories, words }

int favCount(FavScope scope) {
  final starredWords = store.words.where((w) => w.starred).length;
  switch (scope) {
    case FavScope.words:
      return starredWords;
    case FavScope.videos:
      return store.liked.where((id) => videoById(id) != null).length;
    case FavScope.podcasts:
      final ids = {for (final p in podcasts) p.id};
      return store.liked.where(ids.contains).length;
    case FavScope.stories:
      return store.liked.where((id) => storyById(id) != null).length;
    case FavScope.all:
      return store.liked.where((id) => videoById(id) != null || storyById(id) != null).length + starredWords;
  }
}

final _targets = <_FavIconButtonState>{};

/// Звёздочка с бейджем-счётчиком в шапке страницы.
class FavIconButton extends StatefulWidget {
  const FavIconButton({super.key, required this.scope, required this.onPressed, this.tooltip});
  final FavScope scope;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<FavIconButton> createState() => _FavIconButtonState();
}

class _FavIconButtonState extends State<FavIconButton> with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(vsync: this, duration: Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    _targets.add(this);
  }

  @override
  void dispose() {
    _targets.remove(this);
    _bump.dispose();
    super.dispose();
  }

  // Сколько звёздочек ещё летит к иконке: их +1 в счётчике появится, только когда долетят.
  int _inFlight = 0;

  void _hold() => setState(() => _inFlight++);

  void _land() {
    if (!mounted) return;
    setState(() => _inFlight = math.max(0, _inFlight - 1));
    _bump.forward(from: 0);
  }

  /// Иконка сейчас на экране: вкладка активна и страница не закрыта другим экраном.
  bool get _live {
    if (!mounted || !TickerMode.of(context)) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final box = context.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize;
  }

  Offset? get _center {
    final box = context.findRenderObject() as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final n = math.max(0, favCount(widget.scope) - _inFlight);
        return IconButton(
          tooltip: widget.tooltip ?? ui('Избранное'),
          onPressed: widget.onPressed,
          icon: AnimatedBuilder(
            animation: _bump,
            builder: (_, child) {
              final t = _bump.value;
              final scale = 1 + 0.35 * math.sin(t * math.pi);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (t > 0 && t < 1)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 28 + 26 * t,
                          height: 28 + 26 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: cStarOn.withValues(alpha: 1 - t), width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  Transform.scale(scale: scale, child: child),
                  if (n > 0)
                    Positioned(
                      right: -11,
                      top: -9,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          constraints: BoxConstraints(minWidth: 22, minHeight: 22),
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cViolet,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: cBg, width: 1.5),
                          ),
                          child: Text(
                            n > 99 ? '99+' : '$n',
                            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.1, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: Icon(KIcons.star, size: 24, color: cText),
          ),
        );
      },
    );
  }
}

/// Вызывать сразу после того, как элемент добавили в избранное:
/// золотая звёздочка летит от нажатой кнопки к иконке «Избранное» и подсвечивает её.
void flyToFav(BuildContext from) {
  final target = _targets.where((t) => t._live).firstOrNull;
  final srcBox = from.findRenderObject();
  final overlay = Overlay.maybeOf(from, rootOverlay: true);
  if (target == null || overlay == null || srcBox is! RenderBox || !srcBox.attached) return;
  final start = srcBox.localToGlobal(srcBox.size.center(Offset.zero));
  final end = target._center;
  if (end == null) return;
  target._hold();

  late OverlayEntry entry;
  final ctrl = AnimationController(vsync: Navigator.of(from), duration: Duration(milliseconds: 750));
  final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
  // Дуга: середина пути приподнята.
  final mid = Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 70);
  Offset at(double t) {
    final a = Offset.lerp(start, mid, t)!;
    final b = Offset.lerp(mid, end, t)!;
    return Offset.lerp(a, b, t)!;
  }

  entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: curve,
      builder: (_, _) {
        final t = curve.value;
        final p = at(t);
        final size = 46 * (1 - 0.4 * t);
        return Positioned(
          left: p.dx - size / 2,
          top: p.dy - size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: t < 0.85 ? 1 : (1 - t) / 0.15,
              child: Transform.rotate(
                angle: t * math.pi * 2,
                child: Icon(
                  Icons.star_rounded,
                  size: size,
                  color: cStarOn,
                  shadows: [Shadow(color: cStarOn.withValues(alpha: 0.7), blurRadius: 14)],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  overlay.insert(entry);
  ctrl.forward().whenComplete(() {
    entry.remove();
    ctrl.dispose();
    target._land();
  });
}
