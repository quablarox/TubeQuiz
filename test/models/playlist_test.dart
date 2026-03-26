import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/models/playlist.dart';
import 'package:tube_quiz/models/track.dart';

void main() {
  group('Playlist', () {
    test('empty playlist has no tracks', () {
      final playlist = Playlist.empty();
      expect(playlist.isEmpty, true);
      expect(playlist.isNotEmpty, false);
      expect(playlist.length, 0);
    });

    test('playlist with tracks reports correct length', () {
      final tracks = [
        const Track(youtubeId: 'id1', artist: 'A1', title: 'T1'),
        const Track(youtubeId: 'id2', artist: 'A2', title: 'T2'),
      ];
      final playlist = Playlist(
        name: 'Test',
        tracks: tracks,
        importedAt: DateTime.now(),
      );
      expect(playlist.isEmpty, false);
      expect(playlist.isNotEmpty, true);
      expect(playlist.length, 2);
      expect(playlist.name, 'Test');
    });
  });
}
