import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/services/media_control_service.dart';

void main() {
  group('MediaTrackInfo', () {
    test('creates from map with all fields', () {
      final info = MediaTrackInfo.fromMap({
        'title': 'Test Song',
        'artist': 'Test Artist',
        'duration': 240000,
        'position': 60000,
        'isPlaying': true,
      });

      expect(info.title, 'Test Song');
      expect(info.artist, 'Test Artist');
      expect(info.durationMs, 240000);
      expect(info.positionMs, 60000);
      expect(info.isPlaying, true);
      expect(info.durationSeconds, 240);
    });

    test('handles missing fields with defaults', () {
      final info = MediaTrackInfo.fromMap({});

      expect(info.title, '');
      expect(info.artist, '');
      expect(info.durationMs, 0);
      expect(info.positionMs, 0);
      expect(info.isPlaying, false);
    });

    test('handles null values in map', () {
      final info = MediaTrackInfo.fromMap({
        'title': null,
        'artist': null,
        'duration': null,
        'position': null,
        'isPlaying': null,
      });

      expect(info.title, '');
      expect(info.artist, '');
      expect(info.durationMs, 0);
      expect(info.isPlaying, false);
    });
  });
}
