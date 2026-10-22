import 'package:flutter/services.dart';

const _channel = MethodChannel('kapiras/tts');

/// Озвучивает слово сербским голосом (на iOS — AVSpeechSynthesizer в AppDelegate).
Future<void> speakWord(String text) async {
  try {
    await _channel.invokeMethod('speak', text);
  } catch (_) {}
}
