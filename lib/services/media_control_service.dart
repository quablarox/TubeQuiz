import 'package:flutter/services.dart';

/// Represents metadata of the currently playing track from a supported music app.
class MediaTrackInfo {
  final String title;
  final String artist;
  final int durationMs;
  final int positionMs;
  final bool isPlaying;

  const MediaTrackInfo({
    required this.title,
    required this.artist,
    required this.durationMs,
    required this.positionMs,
    required this.isPlaying,
  });

  factory MediaTrackInfo.fromMap(Map<dynamic, dynamic> map) {
    return MediaTrackInfo(
      title: (map['title'] as String?) ?? '',
      artist: (map['artist'] as String?) ?? '',
      durationMs: (map['duration'] as int?) ?? 0,
      positionMs: (map['position'] as int?) ?? 0,
      isPlaying: (map['isPlaying'] as bool?) ?? false,
    );
  }

  int get durationSeconds => (durationMs / 1000).round();

  @override
  String toString() =>
      'MediaTrackInfo(title: $title, artist: $artist, duration: ${durationSeconds}s, playing: $isPlaying)';
}

/// Service that communicates with the native Android platform
/// to control music playback via MediaSession API.
/// Supports YouTube Music, Amazon Music, and other compatible players.
class MediaControlService {
  static const _methodChannel = MethodChannel('com.tubequiz.app/media_control');
  static const _eventChannel = EventChannel('com.tubequiz.app/media_events');

  /// Checks if the notification listener permission is granted.
  Future<bool> isNotificationListenerEnabled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isNotificationListenerEnabled',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system settings page for notification listener permissions.
  Future<void> openNotificationListenerSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationListenerSettings');
    } on PlatformException {
      // Settings could not be opened
    }
  }

  /// Gets the currently playing track info from a supported music app.
  Future<MediaTrackInfo?> getCurrentTrack() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getCurrentTrack',
      );
      if (result == null) return null;
      return MediaTrackInfo.fromMap(result);
    } on PlatformException {
      return null;
    }
  }

  /// Seeks to a specific position in the current track.
  Future<void> seekTo(int positionMs) async {
    try {
      await _methodChannel.invokeMethod('seekTo', {'position': positionMs});
    } on PlatformException {
      // Seek failed
    }
  }

  /// Skips to the next track.
  Future<void> skipToNext() async {
    try {
      await _methodChannel.invokeMethod('skipToNext');
    } on PlatformException {
      // Skip failed
    }
  }

  /// Starts playback.
  Future<void> play() async {
    try {
      await _methodChannel.invokeMethod('play');
    } on PlatformException {
      // Play failed
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    try {
      await _methodChannel.invokeMethod('pause');
    } on PlatformException {
      // Pause failed
    }
  }

  /// Requests AudioFocus so the music app lowers its own output during TTS.
  Future<void> duckAudio() async {
    try {
      await _methodChannel.invokeMethod('duckAudio');
    } on PlatformException {
      // Duck failed
    }
  }

  /// Abandons AudioFocus so the music app restores its output level.
  Future<void> restoreAudio() async {
    try {
      await _methodChannel.invokeMethod('restoreAudio');
    } on PlatformException {
      // Restore failed
    }
  }

  /// Pauses music and boosts STREAM_MUSIC to max for louder TTS.
  Future<void> pauseForTts() async {
    try {
      await _methodChannel.invokeMethod('pauseForTts');
    } on PlatformException {
      // Pause for TTS failed
    }
  }

  /// Restores STREAM_MUSIC volume and resumes music after TTS.
  Future<void> resumeAfterTts() async {
    try {
      await _methodChannel.invokeMethod('resumeAfterTts');
    } on PlatformException {
      // Resume after TTS failed
    }
  }

  /// Returns a stream of media events from the notification listener.
  Stream<Map<dynamic, dynamic>> get mediaEvents {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => event as Map<dynamic, dynamic>,
    );
  }
}
