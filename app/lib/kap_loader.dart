import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Лоадер: жирная фиолетовая š, у которой жёлтая диакритика живёт отдельно — плавно парит и покачивается.
class KapLoader extends StatefulWidget {
  const KapLoader({super.key, this.size = 56});
  final double size;

  @override
  State<KapLoader> createState() => _KapLoaderState();
}

class _KapLoaderState extends State<KapLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: 2400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      label: 'Загрузка',
      child: SizedBox(
        width: s,
        height: s * 1.25,
        child: AnimatedBuilder(
          animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
          builder: (_, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Text(
                  's',
                  style: TextStyle(
                    fontFamily: kFont,
                    fontSize: s,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: cViolet,
                  ),
                ),
                Positioned(
                  top: s * 0.1 - t * s * 0.14,
                  child: Transform.rotate(
                    angle: (t * 12 - 6) * math.pi / 180,
                    child: CustomPaint(size: Size(s * 0.5, s * 0.3), painter: _CaronPainter()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CaronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = cAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.1, h * 0.17)
        ..lineTo(w * 0.5, h * 0.83)
        ..lineTo(w * 0.9, h * 0.17),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Лоадер по центру экрана на цвет фона — для мест, где нечего показать, пока что-то грузится.
class KapLoading extends StatelessWidget {
  const KapLoading({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Center(child: KapLoader(size: size));
}
