/// Controls when TTS announcements are made during playback.
enum AnnounceTiming {
  /// Announce only at the beginning of a song.
  beginning,

  /// Announce only at the end of a song.
  end,

  /// Announce at both beginning and end.
  both,

  /// Announce at beginning, end, and every N seconds in between.
  interval,
}

/// Represents the current state of the engine.
enum QuizStatus {
  /// Service is not running.
  idle,

  /// Service is running and waiting for a track to play.
  waiting,

  /// Currently announcing the track via TTS.
  announcing,

  /// Playing the snippet of the matched track (quiz mode only).
  playingSnippet,

  /// Skipping a non-matching track (quiz mode only).
  skipping,

  /// An error occurred during operation.
  error,
}

/// Holds the complete state of the quiz session.
class QuizState {
  final QuizStatus status;
  final String? currentTitle;
  final String? currentArtist;
  final int snippetDurationSeconds;
  final bool isServiceRunning;
  final bool isQuizMode;
  final bool isFullSong;
  final bool useRandomStart;
  final AnnounceTiming announceTiming;
  final int announceIntervalSeconds;
  final String? errorMessage;
  final int tracksPlayed;
  final int tracksSkipped;
  final int tracksAnnounced;

  const QuizState({
    this.status = QuizStatus.idle,
    this.currentTitle,
    this.currentArtist,
    this.snippetDurationSeconds = 15,
    this.isServiceRunning = false,
    this.isQuizMode = false,
    this.isFullSong = false,
    this.useRandomStart = false,
    this.announceTiming = AnnounceTiming.beginning,
    this.announceIntervalSeconds = 5,
    this.errorMessage,
    this.tracksPlayed = 0,
    this.tracksSkipped = 0,
    this.tracksAnnounced = 0,
  });

  QuizState copyWith({
    QuizStatus? status,
    String? Function()? currentTitle,
    String? Function()? currentArtist,
    int? snippetDurationSeconds,
    bool? isServiceRunning,
    bool? isQuizMode,
    bool? isFullSong,
    bool? useRandomStart,
    AnnounceTiming? announceTiming,
    int? announceIntervalSeconds,
    String? errorMessage,
    int? tracksPlayed,
    int? tracksSkipped,
    int? tracksAnnounced,
  }) {
    return QuizState(
      status: status ?? this.status,
      currentTitle: currentTitle != null ? currentTitle() : this.currentTitle,
      currentArtist:
          currentArtist != null ? currentArtist() : this.currentArtist,
      snippetDurationSeconds:
          snippetDurationSeconds ?? this.snippetDurationSeconds,
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      isQuizMode: isQuizMode ?? this.isQuizMode,
      isFullSong: isFullSong ?? this.isFullSong,
      useRandomStart: useRandomStart ?? this.useRandomStart,
      announceTiming: announceTiming ?? this.announceTiming,
      announceIntervalSeconds:
          announceIntervalSeconds ?? this.announceIntervalSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
      tracksPlayed: tracksPlayed ?? this.tracksPlayed,
      tracksSkipped: tracksSkipped ?? this.tracksSkipped,
      tracksAnnounced: tracksAnnounced ?? this.tracksAnnounced,
    );
  }

  /// Returns a human-readable status label.
  String get statusLabel {
    switch (status) {
      case QuizStatus.idle:
        return 'Idle';
      case QuizStatus.waiting:
        return isQuizMode ? 'Waiting for quiz track...' : 'Listening...';
      case QuizStatus.announcing:
        return 'Announcing track...';
      case QuizStatus.playingSnippet:
        return 'Playing snippet';
      case QuizStatus.skipping:
        return 'Skipping track...';
      case QuizStatus.error:
        return 'Error: ${errorMessage ?? "Unknown"}';
    }
  }
}
