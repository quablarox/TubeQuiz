import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Provider that manages the quiz state and exposes it to the UI.
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
  bool get isQuizActive => _state.isServiceRunning;
  bool get isNotificationListenerEnabled => _isNotificationListenerEnabled;
  int get snippetDuration => _state.snippetDurationSeconds;

  /// Toggles the quiz mode on/off.
  Future<void> toggleQuizMode() async {
    if (_state.isServiceRunning) {
      await _engine.stop();
    } else {
      await _engine.start();
    }
  }

  /// Updates the snippet duration.
  Future<void> setSnippetDuration(int seconds) async {
    _engine.setSnippetDuration(seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('snippet_duration', seconds);
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
      _engine.setSnippetDuration(duration);
      _state = _state.copyWith(snippetDurationSeconds: duration);
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
