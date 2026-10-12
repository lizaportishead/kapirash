import 'package:flutter/widgets.dart';

/// Иконки таббара из набора Phosphor (шрифты лежат в assets/fonts): тонкие — для обычного состояния,
/// обычной толщины — для выбранной вкладки.
abstract final class KIcons {
  static const catalog = IconData(0xe464, fontFamily: 'PhosphorLight');
  static const catalogOn = IconData(0xe464, fontFamily: 'Phosphor');
  static const videos = IconData(0xe8c2, fontFamily: 'PhosphorLight');
  static const videosOn = IconData(0xe8c2, fontFamily: 'Phosphor');
  static const words = IconData(0xe0ea, fontFamily: 'PhosphorLight');
  static const wordsOn = IconData(0xe0ea, fontFamily: 'Phosphor');
  static const profile = IconData(0xe4c2, fontFamily: 'PhosphorLight');
  static const profileOn = IconData(0xe4c2, fontFamily: 'Phosphor');
  static const plus = IconData(0xe3d4, fontFamily: 'Phosphor');
  static const refresh = IconData(0xe036, fontFamily: 'Phosphor');
  static const arrowLeft = IconData(0xe058, fontFamily: 'Phosphor');
  static const arrowRight = IconData(0xe06c, fontFamily: 'Phosphor');
  static const youtube = IconData(0xe4fc, fontFamily: 'Phosphor');
}
