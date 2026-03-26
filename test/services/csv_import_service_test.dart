import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/services/csv_import_service.dart';

void main() {
  late CsvImportService service;

  setUp(() {
    service = CsvImportService();
  });

  group('CsvImportService', () {
    test('parses valid CSV content', () {
      const csv = 'abc123,Queen,Bohemian Rhapsody\ndef456,Beatles,Let It Be';
      final playlist = service.parseFromString(csv, name: 'Test');

      expect(playlist.name, 'Test');
      expect(playlist.length, 2);
      expect(playlist.tracks[0].youtubeId, 'abc123');
      expect(playlist.tracks[0].artist, 'Queen');
      expect(playlist.tracks[0].title, 'Bohemian Rhapsody');
      expect(playlist.tracks[1].youtubeId, 'def456');
      expect(playlist.tracks[1].artist, 'Beatles');
      expect(playlist.tracks[1].title, 'Let It Be');
    });

    test('skips header row', () {
      const csv = 'YouTube_ID,Artist,Title\nabc123,Queen,Bohemian Rhapsody';
      final playlist = service.parseFromString(csv);

      expect(playlist.length, 1);
      expect(playlist.tracks[0].youtubeId, 'abc123');
    });

    test('skips malformed rows', () {
      const csv = 'abc123,Queen,Bohemian Rhapsody\nbadrow\ndef456,Beatles,Let It Be';
      final playlist = service.parseFromString(csv);

      expect(playlist.length, 2);
    });

    test('handles empty CSV content', () {
      const csv = '';
      final playlist = service.parseFromString(csv);

      expect(playlist.isEmpty, true);
    });

    test('handles CSV with only header', () {
      const csv = 'YouTube_ID,Artist,Title';
      final playlist = service.parseFromString(csv);

      expect(playlist.isEmpty, true);
    });

    test('handles CSV with extra columns', () {
      const csv = 'abc123,Queen,Bohemian Rhapsody,extra1,extra2';
      final playlist = service.parseFromString(csv);

      expect(playlist.length, 1);
      expect(playlist.tracks[0].title, 'Bohemian Rhapsody');
    });
  });
}
