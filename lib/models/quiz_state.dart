/// Represents the current state of the quiz engine.
enum QuizStatus {
  /// Quiz mode is disabled.
  idle,

  /// Quiz mode is active and waiting for a track to play.
  waiting,

  /// Currently announcing the track via TTS.
  announcing,

  /// Playing the snippet of the matched track.
  playingSnippet,

  /// Skipping a non-matching track.
  skipping,

  /// An error occurred during quiz operation.
  error,
}

/// Holds the complete state of the quiz session.
class QuizState {
  final QuizStatus status;
  final String? currentTitle;
  final String? currentArtist;
  final int snippetDurationSeconds;
  final bool isServiceRunning;
  final String? errorMessage;
  final int tracksPlayed;
  final int tracksSkipped;

  const QuizState({
    this.status = QuizStatus.idle,
    this.currentTitle,
    this.currentArtist,
    this.snippetDurationSeconds = 15,
    this.isServiceRunning = false,
    this.errorMessage,
    this.tracksPlayed = 0,
    this.tracksSkipped = 0,
  });

  QuizState copyWith({
    QuizStatus? status,
    String? currentTitle,
    String? currentArtist,
    int? snippetDurationSeconds,
    bool? isServiceRunning,
    String? errorMessage,
    int? tracksPlayed,
    int? tracksSkipped,
  }) {
    return QuizState(
      status: status ?? this.status,
      currentTitle: currentTitle ?? this.currentTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      snippetDurationSeconds: snippetDurationSeconds ?? this.snippetDurationSeconds,
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      errorMessage: errorMessage ?? this.errorMessage,
      tracksPlayed: tracksPlayed ?? this.tracksPlayed,
      tracksSkipped: tracksSkipped ?? this.tracksSkipped,
    );
  }

  /// Returns a human-readable status label.
  String get statusLabel {
    switch (status) {
      case QuizStatus.idle:
        return 'Idle';
      case QuizStatus.waiting:
        return 'Waiting for track...';
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
