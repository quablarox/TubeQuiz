import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/models/track.dart';

void main() {
  group('Track', () {
    test('creates from valid CSV row', () {
      final track = Track.fromCsvRow(['abc123', 'Artist Name', 'Song Title']);
      expect(track.youtubeId, 'abc123');
      expect(track.artist, 'Artist Name');
      expect(track.title, 'Song Title');
    });

    test('trims whitespace from CSV values', () {
      final track = Track.fromCsvRow(['  abc123  ', '  Artist  ', '  Title  ']);
      expect(track.youtubeId, 'abc123');
      expect(track.artist, 'Artist');
      expect(track.title, 'Title');
    });

    test('throws on CSV row with fewer than 3 columns', () {
      expect(
        () => Track.fromCsvRow(['abc123', 'Artist']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles CSV row with more than 3 columns', () {
      final track = Track.fromCsvRow(['id', 'artist', 'title', 'extra']);
      expect(track.youtubeId, 'id');
      expect(track.artist, 'artist');
      expect(track.title, 'title');
    });

    test('toMap produces correct map', () {
      const track = Track(youtubeId: 'id1', artist: 'A', title: 'T');
      final map = track.toMap();
      expect(map['youtubeId'], 'id1');
      expect(map['artist'], 'A');
      expect(map['title'], 'T');
    });

    test('equality works correctly', () {
      const t1 = Track(youtubeId: 'id', artist: 'A', title: 'T');
      const t2 = Track(youtubeId: 'id', artist: 'A', title: 'T');
      const t3 = Track(youtubeId: 'id2', artist: 'A', title: 'T');

      expect(t1, equals(t2));
      expect(t1, isNot(equals(t3)));
    });
  });
}
