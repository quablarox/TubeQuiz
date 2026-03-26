import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider that manages the app state and exposes it to the UI.
class QuizProvider extends ChangeNotifier {
  final QuizEngine _engine;
  final CsvImportService _csvImport;
  final MediaControlService _mediaControl;

  QuizState _state = const QuizState();
  Playlist _playlist = Playlist.empty();
  bool _isNotificationListenerEnabled = false;

  QuizProvider({
    QuizEngine? engine,
    CsvImportService? csvImport,
    MediaControlService? mediaControl,
  })  : _engine = engine ?? QuizEngine(),
        _csvImport = csvImport ?? CsvImportService(),
        _mediaControl = mediaControl ?? MediaControlService() {
    _engine.onStateChanged = _onEngineStateChanged;
    _loadSettings();
  }

  // Getters
  QuizState get state => _state;
  Playlist get playlist => _playlist;
  bool get isServiceRunning => _state.isServiceRunning;
  bool get isQuizMode => _state.isQuizMode;
  bool get isFullSong => _state.isFullSong;
  bool get useRandomStart => _state.useRandomStart;
  AnnounceTiming get announceTiming => _state.announceTiming;
  int get announceInterval => _state.announceIntervalSeconds;
  bool get isNotificationListenerEnabled => _isNotificationListenerEnabled;
  int get snippetDuration => _state.snippetDurationSeconds;

  /// Toggles the tracking service on/off (passive mode).
  Future<void> toggleService() async {
    if (_state.isServiceRunning) {
      await _engine.stop();
    } else {
      await _engine.start();
    }
  }

  /// Toggles the quiz mode overlay on/off.
  Future<void> toggleQuizMode() async {
    final newValue = !_state.isQuizMode;
    _engine.setQuizMode(newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiz_mode', newValue);
    notifyListeners();
  }

  /// Updates the snippet duration.
  Future<void> setSnippetDuration(int seconds) async {
    _engine.setSnippetDuration(seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('snippet_duration', seconds);
    notifyListeners();
  }

  /// Toggles full song mode.
  Future<void> toggleFullSong() async {
    final newValue = !_state.isFullSong;
    _engine.setFullSong(newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('full_song', newValue);
    notifyListeners();
  }

  /// Toggles random start position.
  Future<void> toggleRandomStart() async {
    final newValue = !_state.useRandomStart;
    _engine.setRandomStart(newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('random_start', newValue);
    notifyListeners();
  }

  /// Sets the announcement timing mode.
  Future<void> setAnnounceTiming(AnnounceTiming timing) async {
    _engine.setAnnounceTiming(timing);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('announce_timing', timing.index);
    notifyListeners();
  }

  /// Sets the interval for periodic announcements.
  Future<void> setAnnounceInterval(int seconds) async {
    _engine.setAnnounceInterval(seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('announce_interval', seconds);
    notifyListeners();
  }

  /// Imports a CSV playlist file.
  Future<bool> importPlaylist() async {
    final result = await _csvImport.importPlaylist();
    if (result != null && result.isNotEmpty) {
      _playlist = result;
      _engine.setPlaylist(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Clears the loaded playlist.
  void clearPlaylist() {
    _playlist = Playlist.empty();
    _engine.setPlaylist(_playlist);
    notifyListeners();
  }

  /// Checks and updates the notification listener permission status.
  Future<void> checkNotificationListener() async {
    _isNotificationListenerEnabled =
        await _mediaControl.isNotificationListenerEnabled();
    notifyListeners();
  }

  /// Opens notification listener settings.
  Future<void> openNotificationSettings() async {
    await _mediaControl.openNotificationListenerSettings();
  }

  void _onEngineStateChanged(QuizState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final duration = prefs.getInt('snippet_duration') ?? 15;
      final quizMode = prefs.getBool('quiz_mode') ?? false;
      final fullSong = prefs.getBool('full_song') ?? false;
      final randomStart = prefs.getBool('random_start') ?? false;
      final timingIndex = prefs.getInt('announce_timing') ?? 0;
      final interval = prefs.getInt('announce_interval') ?? 5;

      final timing = timingIndex >= 0 && timingIndex < AnnounceTiming.values.length
          ? AnnounceTiming.values[timingIndex]
          : AnnounceTiming.beginning;

      _engine.setSnippetDuration(duration);
      _engine.setQuizMode(quizMode);
      _engine.setFullSong(fullSong);
      _engine.setRandomStart(randomStart);
      _engine.setAnnounceTiming(timing);
      _engine.setAnnounceInterval(interval);

      _state = _state.copyWith(
        snippetDurationSeconds: duration,
        isQuizMode: quizMode,
        isFullSong: fullSong,
        useRandomStart: randomStart,
        announceTiming: timing,
        announceIntervalSeconds: interval,
      );
    } catch (e) {
      // Use defaults if preferences unavailable
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}
