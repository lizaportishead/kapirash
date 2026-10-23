// Podcast audio: native uses audioplayers; web uses a plain <audio> element,
// because audioplayers_web forces crossOrigin=anonymous and fails on hosts without CORS headers.
export 'pod_audio_native.dart' if (dart.library.js_interop) 'pod_audio_web.dart';
