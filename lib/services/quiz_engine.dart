import 'dart:async';
import 'dart:math';
import '../models/models.dart';
import 'media_control_service.dart';
import 'fuzzy_match_service.dart';
import 'tts_service.dart';

/// The core engine that orchestrates passive tracking and quiz behavior.
///
/// Always runs in passive mode: detects tracks and announces them via TTS.
/// When quiz mode is enabled, additionally controls playback (playlist
/// filtering, snippet duration, seeking, and skipping).
class QuizEngine {
  final MediaControlService _mediaControl;
  final FuzzyMatchService _fuzzyMatch;
  final TtsService _ttsService;

  Timer? _pollTimer;
  Timer? _snippetTimer;
  Timer? _intervalAnnounceTimer;
  bool _isRunning = false;
  String? _lastProcessedTitle;
  String? _currentTrackTitle;
  int _lastAnnouncedPositionMs = 0;
  bool _hasAnnouncedEnd = false;

  /// Callback for state changes.
  void Function(QuizState state)? onStateChanged;

  QuizState _state = const QuizState();
  Playlist _playlist = Playlist.empty();

  /// Maximum random start position in milliseconds (1:30).
  static const int _maxRandomStartMs = 90000;

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

  /// Enables or disables quiz mode overlay.
  void setQuizMode(bool enabled) {
    _updateState(_state.copyWith(isQuizMode: enabled));
  }

  /// Sets whether to play the full song in quiz mode.
  void setFullSong(bool enabled) {
    _updateState(_state.copyWith(isFullSong: enabled));
  }

  /// Sets whether to use a random start position.
  void setRandomStart(bool enabled) {
    _updateState(_state.copyWith(useRandomStart: enabled));
  }

  /// Sets the announcement timing mode.
  void setAnnounceTiming(AnnounceTiming timing) {
    _updateState(_state.copyWith(announceTiming: timing));
  }

  /// Sets the interval for periodic announcements (in seconds).
  void setAnnounceInterval(int seconds) {
    _updateState(_state.copyWith(announceIntervalSeconds: seconds));
  }

  /// Starts the engine (passive tracking + optional quiz).
  Future<void> start() async {
    if (_isRunning) return;

    await _ttsService.initialize();
    _isRunning = true;
    _lastProcessedTitle = null;
    _currentTrackTitle = null;
    _hasAnnouncedEnd = false;

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

  /// Stops the engine.
  Future<void> stop() async {
    _isRunning = false;
    _pollTimer?.cancel();
    _snippetTimer?.cancel();
    _intervalAnnounceTimer?.cancel();
    _pollTimer = null;
    _snippetTimer = null;
    _intervalAnnounceTimer = null;
    _lastProcessedTitle = null;
    _currentTrackTitle = null;

    await _ttsService.stop();
    await _mediaControl.restoreAudio();

    _updateState(const QuizState(
      status: QuizStatus.idle,
      isServiceRunning: false,
    ));
  }

  /// Core polling logic: checks what's playing and applies rules.
  Future<void> _pollCurrentTrack() async {
    if (!_isRunning) return;

    // Don't poll while announcing or in an active quiz action
    if (_state.status == QuizStatus.announcing ||
        _state.status == QuizStatus.skipping) {
      return;
    }

    // In quiz mode with snippet playing, don't process new tracks
    if (_state.isQuizMode && _state.status == QuizStatus.playingSnippet) {
      return;
    }

    try {
      final trackInfo = await _mediaControl.getCurrentTrack();

      if (trackInfo == null || !trackInfo.isPlaying) {
        return;
      }

      // Check if this is a new track
      if (trackInfo.title != _lastProcessedTitle) {
        _lastProcessedTitle = trackInfo.title;
        _currentTrackTitle = trackInfo.title;
        _hasAnnouncedEnd = false;
        _intervalAnnounceTimer?.cancel();
        await _processNewTrack(trackInfo);
        return;
      }

      // For existing track: handle end-of-song and interval announcements
      await _handleOngoingAnnouncements(trackInfo);
    } catch (e) {
      _updateState(_state.copyWith(
        status: QuizStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Processes a newly detected track.
  Future<void> _processNewTrack(MediaTrackInfo trackInfo) async {
    if (!_isRunning) return;

    if (_state.isQuizMode) {
      await _processQuizTrack(trackInfo);
    } else {
      await _processPassiveTrack(trackInfo);
    }
  }

  /// Passive mode: announce the track and let it play.
  Future<void> _processPassiveTrack(MediaTrackInfo trackInfo) async {
    if (!_isRunning) return;

    _updateState(_state.copyWith(
      currentTitle: () => trackInfo.title,
      currentArtist: () => trackInfo.artist,
    ));

    // Announce at beginning if configured
    if (_shouldAnnounceAtBeginning()) {
      await _announce(trackInfo.title, trackInfo.artist);
    }

    // Start interval timer if configured
    _startIntervalAnnouncements(trackInfo);

    _updateState(_state.copyWith(status: QuizStatus.waiting));
  }

  /// Quiz mode: match against playlist, then either skip or run quiz action.
  Future<void> _processQuizTrack(MediaTrackInfo trackInfo) async {
    if (!_isRunning) return;

    final hasPlaylist = _playlist.isNotEmpty;

    if (hasPlaylist) {
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

      await _runQuizAction(trackInfo, match.title, match.artist);
    } else {
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

    // Announce at beginning if configured
    if (_shouldAnnounceAtBeginning()) {
      _updateState(_state.copyWith(
        status: QuizStatus.announcing,
        currentTitle: () => title,
        currentArtist: () => artist,
      ));

      await _announce(title, artist);

      if (!_isRunning) return;
    } else {
      _updateState(_state.copyWith(
        currentTitle: () => title,
        currentArtist: () => artist,
      ));
    }

    if (_state.isFullSong) {
      // Full song mode: let it play, just track it
      _updateState(_state.copyWith(status: QuizStatus.playingSnippet));
      await _mediaControl.play();

      // Start interval announcements if configured
      _startIntervalAnnouncements(trackInfo);

      // In full song mode, we wait for the track to change naturally.
      // The poll loop will detect the change and process the next track.
      // Use a timer to check periodically if the song ended.
      _snippetTimer?.cancel();
      _snippetTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) async {
          if (!_isRunning || !_state.isQuizMode) {
            _snippetTimer?.cancel();
            return;
          }

          final current = await _mediaControl.getCurrentTrack();
          if (current == null ||
              current.title != _currentTrackTitle ||
              !current.isPlaying) {
            _snippetTimer?.cancel();
            _intervalAnnounceTimer?.cancel();

            _updateState(_state.copyWith(
              tracksPlayed: _state.tracksPlayed + 1,
              status: QuizStatus.waiting,
              currentTitle: () => null,
              currentArtist: () => null,
            ));

            _lastProcessedTitle = null;
          }
        },
      );
    } else {
      // Snippet mode: seek and play for configured duration
      final snippetMs = _state.snippetDurationSeconds * 1000;
      final trackDurationMs = trackInfo.durationMs;

      if (trackDurationMs > 0 && _state.useRandomStart) {
        // Random start: cap at 1:30min - snippet length
        final maxRandomMs = _maxRandomStartMs - snippetMs;
        final maxStartMs = trackDurationMs - snippetMs;
        final effectiveMax =
            maxStartMs > 0 ? min(maxStartMs, max(0, maxRandomMs)) : 0;
        if (effectiveMax > 0) {
          final random = Random();
          final randomStartMs = random.nextInt(effectiveMax);
          await _mediaControl.seekTo(randomStartMs);
        }
      } else if (trackDurationMs > 0 && !_state.useRandomStart) {
        // No random start: play from beginning
        await _mediaControl.seekTo(0);
      }

      _updateState(_state.copyWith(status: QuizStatus.playingSnippet));
      await _mediaControl.play();

      // Start interval announcements if configured
      _startIntervalAnnouncements(trackInfo);

      // Wait for snippet duration, then skip
      _snippetTimer?.cancel();
      _snippetTimer = Timer(
        Duration(seconds: _state.snippetDurationSeconds),
        () async {
          if (!_isRunning) return;

          _intervalAnnounceTimer?.cancel();

          // Announce at end if configured
          if (_shouldAnnounceAtEnd() && !_hasAnnouncedEnd) {
            _hasAnnouncedEnd = true;
            await _announce(title, artist);
          }

          _updateState(_state.copyWith(
            tracksPlayed: _state.tracksPlayed + 1,
          ));

          // Skip to next track
          await _mediaControl.skipToNext();

          _updateState(_state.copyWith(
            status: QuizStatus.waiting,
            currentTitle: () => null,
            currentArtist: () => null,
          ));

          _lastProcessedTitle = null;
        },
      );
    }
  }

  /// Handles ongoing announcements for the current track (end, interval).
  Future<void> _handleOngoingAnnouncements(MediaTrackInfo trackInfo) async {
    if (!_isRunning) return;

    // Handle end-of-song announcement in passive mode
    if (!_state.isQuizMode && _shouldAnnounceAtEnd() && !_hasAnnouncedEnd) {
      final durationMs = trackInfo.durationMs;
      final positionMs = trackInfo.positionMs;
      // Announce ~5 seconds before the end
      if (durationMs > 0 && positionMs > 0) {
        final remainingMs = durationMs - positionMs;
        if (remainingMs <= 5000 && remainingMs >= 0) {
          _hasAnnouncedEnd = true;
          final title = _state.currentTitle ?? trackInfo.title;
          final artist = _state.currentArtist ?? trackInfo.artist;
          await _announce(title, artist);
        }
      }
    }
  }

  /// Starts periodic interval announcements if configured.
  void _startIntervalAnnouncements(MediaTrackInfo trackInfo) {
    _intervalAnnounceTimer?.cancel();

    if (_state.announceTiming != AnnounceTiming.interval) return;

    final intervalMs = _state.announceIntervalSeconds * 1000;
    _lastAnnouncedPositionMs = 0;

    _intervalAnnounceTimer = Timer.periodic(
      Duration(seconds: _state.announceIntervalSeconds),
      (_) async {
        if (!_isRunning) {
          _intervalAnnounceTimer?.cancel();
          return;
        }

        final current = await _mediaControl.getCurrentTrack();
        if (current == null || current.title != _currentTrackTitle) {
          _intervalAnnounceTimer?.cancel();
          return;
        }

        final durationMs = current.durationMs;
        final positionMs = current.positionMs;
        final remainingMs = durationMs - positionMs;

        // Skip if remaining time is less than the interval
        if (durationMs > 0 && remainingMs < intervalMs) {
          return;
        }

        _lastAnnouncedPositionMs = positionMs;

        final title = _state.currentTitle ?? current.title;
        final artist = _state.currentArtist ?? current.artist;
        await _announce(title, artist);
      },
    );
  }

  /// Announces a track via TTS with audio ducking.
  Future<void> _announce(String title, String artist) async {
    final prevStatus = _state.status;
    _updateState(_state.copyWith(status: QuizStatus.announcing));

    await _mediaControl.duckAudio();
    await _ttsService.announceTrack(title, artist);
    await _mediaControl.restoreAudio();

    _updateState(_state.copyWith(
      status: prevStatus == QuizStatus.announcing ? QuizStatus.waiting : prevStatus,
      tracksAnnounced: _state.tracksAnnounced + 1,
    ));
  }

  /// Skips a non-matching track immediately (quiz mode).
  Future<void> _skipTrack() async {
    _updateState(_state.copyWith(status: QuizStatus.skipping));

    await _mediaControl.skipToNext();

    _updateState(_state.copyWith(
      status: QuizStatus.waiting,
      tracksSkipped: _state.tracksSkipped + 1,
    ));

    _lastProcessedTitle = null;
  }

  bool _shouldAnnounceAtBeginning() {
    final timing = _state.announceTiming;
    return timing == AnnounceTiming.beginning ||
        timing == AnnounceTiming.both ||
        timing == AnnounceTiming.interval;
  }

  bool _shouldAnnounceAtEnd() {
    final timing = _state.announceTiming;
    return timing == AnnounceTiming.end ||
        timing == AnnounceTiming.both ||
        timing == AnnounceTiming.interval;
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
