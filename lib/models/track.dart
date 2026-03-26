/// Represents a single track entry from the imported CSV playlist.
class Track {
  final String youtubeId;
  final String artist;
  final String title;

  const Track({
    required this.youtubeId,
    required this.artist,
    required this.title,
  });

  /// Creates a Track from a CSV row [youtubeId, artist, title].
  factory Track.fromCsvRow(List<dynamic> row) {
    if (row.length < 3) {
      throw ArgumentError('CSV row must have at least 3 columns: YouTube_ID, Artist, Title');
    }
    return Track(
      youtubeId: row[0].toString().trim(),
      artist: row[1].toString().trim(),
      title: row[2].toString().trim(),
    );
  }

  Map<String, String> toMap() {
    return {
      'youtubeId': youtubeId,
      'artist': artist,
      'title': title,
    };
  }

  @override
  String toString() => 'Track(title: $title, artist: $artist, id: $youtubeId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          youtubeId == other.youtubeId &&
          artist == other.artist &&
          title == other.title;

  @override
  int get hashCode => youtubeId.hashCode ^ artist.hashCode ^ title.hashCode;
}
