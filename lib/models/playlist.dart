import 'track.dart';

/// Represents a loaded playlist containing tracks from an imported CSV file.
class Playlist {
  final String name;
  final List<Track> tracks;
  final DateTime importedAt;

  const Playlist({
    required this.name,
    required this.tracks,
    required this.importedAt,
  });

  /// Creates an empty playlist.
  factory Playlist.empty() {
    return Playlist(
      name: '',
      tracks: const [],
      importedAt: DateTime.now(),
    );
  }

  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;
  int get length => tracks.length;

  @override
  String toString() => 'Playlist(name: $name, tracks: ${tracks.length})';
}
