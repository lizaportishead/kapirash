import 'package:web/web.dart' as web;

/// Озвучивает слово сербским голосом через speechSynthesis браузера.
Future<void> speakWord(String text) async {
  try {
    web.window.speechSynthesis.cancel();
    final u = web.SpeechSynthesisUtterance(text)
      ..lang = 'sr-RS'
      ..rate = 0.8;
    web.window.speechSynthesis.speak(u);
  } catch (_) {}
}
