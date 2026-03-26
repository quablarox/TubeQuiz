import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';

/// Service responsible for importing and parsing CSV playlist files.
class CsvImportService {
  /// Opens a file picker and imports a CSV file.
  /// CSV format expected: YouTube_ID, Artist, Title
  ///
  /// Returns a [Playlist] with the parsed tracks, or null if cancelled.
  Future<Playlist?> importPlaylist() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final fileName = file.name;

    if (file.bytes != null) {
      return _parseCSV(utf8.decode(file.bytes!), fileName);
    }

    if (file.path != null) {
      final content = await File(file.path!).readAsString();
      return _parseCSV(content, fileName);
    }

    return null;
  }

  /// Parses a CSV string into a Playlist.
  Playlist parseFromString(String csvContent, {String name = 'Imported Playlist'}) {
    return _parseCSV(csvContent, name);
  }

  Playlist _parseCSV(String content, String fileName) {
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    final tracks = <Track>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      // Skip header row if detected
      if (i == 0 && _isHeaderRow(row)) {
        continue;
      }

      if (row.length >= 3) {
        try {
          tracks.add(Track.fromCsvRow(row));
        } catch (e) {
          // Skip malformed rows
          continue;
        }
      }
    }

    return Playlist(
      name: fileName.replaceAll('.csv', ''),
      tracks: tracks,
      importedAt: DateTime.now(),
    );
  }

  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;
    final firstCell = row[0].toString().toLowerCase();
    return firstCell.contains('youtube') ||
        firstCell.contains('id') ||
        firstCell.contains('video');
  }
}
