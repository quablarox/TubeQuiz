import 'package:flutter_tts/flutter_tts.dart';

/// Service that handles Text-to-Speech announcements during the quiz.
class TtsService {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  /// Initializes the TTS engine.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);
    _isInitialized = true;
  }

  /// Announces the upcoming track via TTS.
  /// Returns a Future that completes when the announcement is finished.
  Future<void> announceTrack(String title, String artist) async {
    await initialize();
    final text = 'Next song: $title by $artist';
    await _speak(text);
  }

  /// Speaks the given text and waits for completion.
  Future<void> _speak(String text) async {
    if (_flutterTts == null) return;

    final completer = Future<void>.delayed(Duration.zero);
    bool completed = false;

    _flutterTts!.setCompletionHandler(() {
      completed = true;
    });

    await _flutterTts!.speak(text);

    // Wait for TTS completion with timeout
    int elapsed = 0;
    while (!completed && elapsed < 10000) {
      await Future.delayed(const Duration(milliseconds: 100));
      elapsed += 100;
    }
  }

  /// Stops any ongoing TTS playback.
  Future<void> stop() async {
    await _flutterTts?.stop();
  }

  /// Releases TTS resources.
  Future<void> dispose() async {
    await _flutterTts?.stop();
    _isInitialized = false;
  }
}
