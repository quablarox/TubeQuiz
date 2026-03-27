import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Service that handles Text-to-Speech announcements during the quiz.
class TtsService {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  /// Words that commonly appear in brackets but are not part of the song title.
  /// When found inside parentheses or square brackets, the entire bracket
  /// group is removed before the title is read aloud.
  static const _bracketNoiseWords = [
    'explicit',
    'remix',
    'remixed',
    'remaster',
    'remastered',
    'live',
    'feat',
    'ft',
    'featuring',
    'acoustic',
    'deluxe',
    'bonus',
    'bonus track',
    'version',
    'edit',
    'radio',
    'radio edit',
    'demo',
    'mono',
    'stereo',
    'single',
    'album',
    'official',
    'official video',
    'official audio',
    'official music video',
    'video',
    'audio',
    'lyrics',
    'lyric',
    'lyric video',
    'visualizer',
    'visualiser',
    'clean',
    'dirty',
    'extended',
    'instrumental',
    'original',
    'original mix',
    'club mix',
    'dub mix',
    'sped up',
    'slowed',
    'reverb',
    'nightcore',
  ];

  /// Pre-compiled pattern that matches bracket groups containing noise words.
  static final RegExp _noisePattern = _buildNoisePattern();

  static RegExp _buildNoisePattern() {
    final escaped =
        _bracketNoiseWords.map((w) => RegExp.escape(w)).join('|');
    // Match (...) or [...] whose content contains at least one noise word
    return RegExp(
      r'[\(\[]((?:[^\)\]])*?\b(?:' + escaped + r')\b[^\)\]]*?)[\)\]]',
      caseSensitive: false,
    );
  }

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

  /// Removes bracketed noise from a title for cleaner TTS output.
  ///
  /// Strips content inside `()` or `[]` when it contains typical non-title
  /// words such as "Explicit", "Remix", "Live", "feat.", etc.
  static String cleanTitleForSpeech(String title) {
    return title
        .replaceAll(_noisePattern, '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Announces the upcoming track via TTS.
  /// Returns a Future that completes when the announcement is finished.
  Future<void> announceTrack(String title, String artist) async {
    await initialize();
    final cleanTitle = cleanTitleForSpeech(title);
    final text = '$cleanTitle by $artist';
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
