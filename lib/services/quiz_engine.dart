import 'dart:async';
import 'dart:math';
import '../models/models.dart';
import 'media_control_service.dart';
import 'fuzzy_match_service.dart';
import 'tts_service.dart';

/// The core Quiz Loop engine that orchestrates the entire quiz behavior.
///
/// When Quiz Mode is active and music is playing in YouTube Music:
/// 1. Detect & Match: Read current track metadata, check against playlist
/// 2. Quiz Action (match or no CSV): Announce via TTS, jump to random timestamp,
///    play for snippet duration, then skip
/// 3. Skip Action (CSV loaded, no match): Skip immediately
class QuizEngine {
  final MediaControlService _mediaControl;
  final FuzzyMatchService _fuzzyMatch;
  final TtsService _ttsService;

  Timer? _pollTimer;
  Timer? _snippetTimer;
  bool _isRunning = false;
  String? _lastProcessedTitle;

  /// Callback for state changes.
  void Function(QuizState state)? onStateChanged;

  QuizState _state = const QuizState();
  Playlist _playlist = Playlist.empty();

  QuizEngine({
    MediaControlService? mediaControl,
    FuzzyMatchService? fuzzyMatch,
    TtsService? ttsService,
  })  : _mediaControl = mediaControl ?? MediaControlService(),
        _fuzzyMatch = fuzzyMatch ?? FuzzyMatchService(),
        _ttsService = ttsService ?? TtsService();

  QuizState get state => _state;
  Playlist get playlist => _playlist;
  bool get isRunning => _isRunning;

  /// Updates the loaded playlist.
  void setPlaylist(Playlist playlist) {
    _playlist = playlist;
    _updateState(_state.copyWith());
  }

  /// Updates the snippet duration setting.
  void setSnippetDuration(int seconds) {
    _updateState(_state.copyWith(snippetDurationSeconds: seconds));
  }

  /// Starts the quiz loop.
  Future<void> start() async {
    if (_isRunning) return;

    await _ttsService.initialize();
    _isRunning = true;
    _lastProcessedTitle = null;

    _updateState(_state.copyWith(
      status: QuizStatus.waiting,
      isServiceRunning: true,
      errorMessage: null,
    ));

    // Poll for track changes every 2 seconds
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollCurrentTrack(),
    );
  }

  /// Stops the quiz loop.
  Future<void> stop() async {
    _isRunning = false;
    _pollTimer?.cancel();
    _snippetTimer?.cancel();
    _pollTimer = null;
    _snippetTimer = null;
    _lastProcessedTitle = null;

    await _ttsService.stop();

    _updateState(const QuizState(
      status: QuizStatus.idle,
      isServiceRunning: false,
    ));
  }

  /// Core polling logic: checks what's playing and applies quiz rules.
  Future<void> _pollCurrentTrack() async {
    if (!_isRunning) return;

    // Don't poll while announcing or playing snippet
    if (_state.status == QuizStatus.announcing ||
        _state.status == QuizStatus.playingSnippet ||
        _state.status == QuizStatus.skipping) {
      return;
    }

    try {
      final trackInfo = await _mediaControl.getCurrentTrack();

      if (trackInfo == null || !trackInfo.isPlaying) {
        return;
      }

      // Skip if we already processed this track
      if (trackInfo.title == _lastProcessedTitle) {
        return;
      }

      _lastProcessedTitle = trackInfo.title;
      await _processTrack(trackInfo);
    } catch (e) {
      _updateState(_state.copyWith(
        status: QuizStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Processes a detected track according to quiz rules.
  Future<void> _processTrack(MediaTrackInfo trackInfo) async {
    if (!_isRunning) return;

    final hasPlaylist = _playlist.isNotEmpty;

    if (hasPlaylist) {
      // Check if the current track matches the playlist
      final match = _fuzzyMatch.findMatch(
        trackInfo.title,
        trackInfo.artist,
        _playlist.tracks,
      );

      if (match == null) {
        // No match: skip immediately
        await _skipTrack();
        return;
      }

      // Match found: run quiz action
      await _runQuizAction(trackInfo, match.title, match.artist);
    } else {
      // No CSV loaded: treat every track as a quiz track
      await _runQuizAction(trackInfo, trackInfo.title, trackInfo.artist);
    }
  }

  /// Executes the quiz action: announce, seek, play snippet, skip.
  Future<void> _runQuizAction(
    MediaTrackInfo trackInfo,
    String title,
    String artist,
  ) async {
    if (!_isRunning) return;

    // Step 1: Announce via TTS
    _updateState(_state.copyWith(
      status: QuizStatus.announcing,
      currentTitle: () => title,
      currentArtist: () => artist,
    ));

    await _ttsService.announceTrack(title, artist);

    if (!_isRunning) return;

    // Step 2: Seek to random position
    final snippetMs = _state.snippetDurationSeconds * 1000;
    final trackDurationMs = trackInfo.durationMs;

    if (trackDurationMs > 0) {
      // Ensure enough time remains for the snippet
      final maxStartMs = trackDurationMs - snippetMs;
      if (maxStartMs > 0) {
        final random = Random();
        final randomStartMs = random.nextInt(maxStartMs);
        await _mediaControl.seekTo(randomStartMs);
      }
    }

    // Step 3: Play snippet for the configured duration
    _updateState(_state.copyWith(
      status: QuizStatus.playingSnippet,
    ));

    await _mediaControl.play();

    // Wait for snippet duration, then skip
    _snippetTimer?.cancel();
    _snippetTimer = Timer(
      Duration(seconds: _state.snippetDurationSeconds),
      () async {
        if (!_isRunning) return;

        _updateState(_state.copyWith(
          tracksPlayed: _state.tracksPlayed + 1,
        ));

        // Step 4: Skip to next track
        await _mediaControl.skipToNext();

        _updateState(_state.copyWith(
          status: QuizStatus.waiting,
          currentTitle: () => null,
          currentArtist: () => null,
        ));

        // Reset so we can process the next track
        _lastProcessedTitle = null;
      },
    );
  }

  /// Skips a non-matching track immediately.
  Future<void> _skipTrack() async {
    _updateState(_state.copyWith(status: QuizStatus.skipping));

    await _mediaControl.skipToNext();

    _updateState(_state.copyWith(
      status: QuizStatus.waiting,
      tracksSkipped: _state.tracksSkipped + 1,
    ));

    // Reset so we can process the next track
    _lastProcessedTitle = null;
  }

  void _updateState(QuizState newState) {
    _state = newState;
    onStateChanged?.call(_state);
  }

  /// Releases all resources.
  Future<void> dispose() async {
    await stop();
    await _ttsService.dispose();
  }
}
