import 'package:flutter/services.dart';

const _channel = MethodChannel('kapiras/tts');

/// Запасной вариант: озвучивает слово сербским голосом (на iOS — AVSpeechSynthesizer в AppDelegate).
Future<void> speakWordSystem(String text) async {
  try {
    await _channel.invokeMethod('speak', text);
  } catch (_) {}
}
