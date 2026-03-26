import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/services/fuzzy_match_service.dart';
import 'package:tube_quiz/models/track.dart';

void main() {
  late FuzzyMatchService service;

  setUp(() {
    service = FuzzyMatchService();
  });

  group('FuzzyMatchService', () {
    final tracks = [
      const Track(youtubeId: 'id1', artist: 'Queen', title: 'Bohemian Rhapsody'),
      const Track(youtubeId: 'id2', artist: 'The Beatles', title: 'Let It Be'),
      const Track(youtubeId: 'id3', artist: 'Pink Floyd', title: 'Comfortably Numb'),
      const Track(youtubeId: 'id4', artist: 'Led Zeppelin', title: 'Stairway to Heaven'),
      const Track(youtubeId: 'id5', artist: 'Nirvana', title: 'Smells Like Teen Spirit'),
    ];

    test('exact match returns correct track', () {
      final result = service.findMatch('Bohemian Rhapsody', 'Queen', tracks);
      expect(result, isNotNull);
      expect(result!.youtubeId, 'id1');
    });

    test('case-insensitive match works', () {
      final result = service.findMatch('bohemian rhapsody', 'queen', tracks);
      expect(result, isNotNull);
      expect(result!.youtubeId, 'id1');
    });

    test('match with extra whitespace works', () {
      final result = service.findMatch('  Bohemian  Rhapsody  ', '  Queen  ', tracks);
      expect(result, isNotNull);
      expect(result!.youtubeId, 'id1');
    });

    test('partial title match works', () {
      final result = service.findMatch('Bohemian Rhapsody (Official Video)', 'Queen', tracks);
      expect(result, isNotNull);
      expect(result!.youtubeId, 'id1');
    });

    test('returns null for non-matching track', () {
      final result = service.findMatch('Completely Unknown Song', 'Unknown Artist', tracks);
      expect(result, isNull);
    });

    test('returns null for empty tracks list', () {
      final result = service.findMatch('Bohemian Rhapsody', 'Queen', []);
      expect(result, isNull);
    });

    test('handles feat. in track titles', () {
      final tracksWithFeat = [
        const Track(youtubeId: 'id1', artist: 'Artist', title: 'Song Name'),
      ];
      final result = service.findMatch(
        'Song Name (feat. Other Artist)',
        'Artist',
        tracksWithFeat,
      );
      expect(result, isNotNull);
      expect(result!.youtubeId, 'id1');
    });

    test('matches with slightly different artist names', () {
      final result = service.findMatch('Let It Be', 'Beatles', tracks);
      expect(result, isNotNull);
      expect(result!.youtubeId, 'id2');
    });
  });
}
