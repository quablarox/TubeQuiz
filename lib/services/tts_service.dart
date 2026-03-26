import 'dart:async';
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
    final text = '$title by $artist';
    await _speak(text);
  }

  /// Speaks the given text and waits for completion.
  Future<void> _speak(String text) async {
    if (_flutterTts == null) return;

    final completer = Completer<void>();

    _flutterTts!.setCompletionHandler(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _flutterTts!.setErrorHandler((message) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await _flutterTts!.speak(text);

    // Wait for TTS completion with timeout
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
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
