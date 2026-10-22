import 'package:flutter/widgets.dart';

/// Видео в хиро лендинга есть только в вебе; на телефоне лендинга нет.
class HeroVideo extends StatelessWidget {
  const HeroVideo({super.key, required this.src, required this.onTime, this.seconds = 10});
  final String src;
  final double seconds;
  final ValueChanged<double> onTime;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
