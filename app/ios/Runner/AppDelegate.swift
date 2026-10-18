import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let synth = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "kapiras/tts", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "speak", let text = call.arguments as? String, let synth = self?.synth else {
        result(FlutterMethodNotImplemented)
        return
      }
      try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
      try? AVAudioSession.sharedInstance().setActive(true)
      synth.stopSpeaking(at: .immediate)
      let u = AVSpeechUtterance(string: text)
      u.voice = AVSpeechSynthesisVoice(language: "sr-RS") ?? AVSpeechSynthesisVoice(language: "hr-HR")
      u.rate = 0.42
      synth.speak(u)
      result(nil)
    }
  }
}
