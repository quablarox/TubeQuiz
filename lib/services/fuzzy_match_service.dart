import '../models/models.dart';

/// Service that performs fuzzy string matching to determine if a
/// currently playing track matches any track in the imported playlist.
///
/// Uses case-insensitive comparison with fuzzy matching to handle
/// slight differences in track names between YouTube Music and the CSV.
class FuzzyMatchService {
  /// Minimum similarity ratio (0-100) to consider a match.
  static const int defaultThreshold = 70;

  /// Checks if the given [title] and [artist] from YouTube Music
  /// match any track in the [playlist].
  ///
  /// Returns the matching [Track] or null if no match is found.
  Track? findMatch(String title, String artist, List<Track> tracks) {
    if (tracks.isEmpty) return null;

    final normalizedTitle = _normalize(title);
    final normalizedArtist = _normalize(artist);

    Track? bestMatch;
    int bestScore = 0;

    for (final track in tracks) {
      final trackTitle = _normalize(track.title);
      final trackArtist = _normalize(track.artist);

      // Calculate combined title + artist similarity
      final titleScore = _similarityScore(normalizedTitle, trackTitle);
      final artistScore = _similarityScore(normalizedArtist, trackArtist);

      // Weighted score: title is more important than artist
      final combinedScore = ((titleScore * 0.7) + (artistScore * 0.3)).round();

      if (combinedScore > bestScore && combinedScore >= defaultThreshold) {
        bestScore = combinedScore;
        bestMatch = track;
      }
    }

    return bestMatch;
  }

  /// Normalizes a string for comparison by converting to lowercase
  /// and removing common noise characters.
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\{\}]'), '')
        .replaceAll(RegExp(r'\s*(feat\.?|ft\.?|featuring)\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculates a similarity score between two strings (0-100).
  /// Uses a combination of exact match, contains check, and
  /// Levenshtein-based ratio.
  int _similarityScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 100;

    // Check if one string contains the other
    if (a.contains(b) || b.contains(a)) {
      final shorter = a.length < b.length ? a : b;
      final longer = a.length >= b.length ? a : b;
      return (shorter.length / longer.length * 100).round().clamp(70, 95);
    }

    // Token-based matching
    final tokensA = a.split(' ').where((t) => t.isNotEmpty).toSet();
    final tokensB = b.split(' ').where((t) => t.isNotEmpty).toSet();

    if (tokensA.isNotEmpty && tokensB.isNotEmpty) {
      final intersection = tokensA.intersection(tokensB);
      final union = tokensA.union(tokensB);
      final jaccardScore = (intersection.length / union.length * 100).round();

      // Also compute Levenshtein ratio
      final levenshteinRatio = _levenshteinRatio(a, b);

      // Take the better of the two scores
      return jaccardScore > levenshteinRatio ? jaccardScore : levenshteinRatio;
    }

    return _levenshteinRatio(a, b);
  }

  /// Calculates Levenshtein-based similarity ratio (0-100).
  int _levenshteinRatio(String a, String b) {
    final distance = _levenshteinDistance(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    if (maxLength == 0) return 100;
    return ((1 - distance / maxLength) * 100).round();
  }

  /// Computes the Levenshtein edit distance between two strings.
  int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final List<List<int>> matrix = List.generate(
      s.length + 1,
      (i) => List.generate(t.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }
}
