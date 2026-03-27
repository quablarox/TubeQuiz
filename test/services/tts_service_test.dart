import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/services/tts_service.dart';

void main() {
  group('TtsService.cleanTitleForSpeech', () {
    test('returns title unchanged when no brackets present', () {
      expect(
        TtsService.cleanTitleForSpeech('Bohemian Rhapsody'),
        'Bohemian Rhapsody',
      );
    });

    test('removes (Explicit) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Bad Guy (Explicit)'),
        'Bad Guy',
      );
    });

    test('removes [Explicit] from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Bad Guy [Explicit]'),
        'Bad Guy',
      );
    });

    test('removes (Remix) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Blinding Lights (Remix)'),
        'Blinding Lights',
      );
    });

    test('removes (feat. Artist) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (feat. Other Artist)'),
        'Song Name',
      );
    });

    test('removes (ft. Artist) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (ft. DJ Snake)'),
        'Song Name',
      );
    });

    test('removes (Live) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Hotel California (Live)'),
        'Hotel California',
      );
    });

    test('removes (Official Video) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Never Gonna Give You Up (Official Video)'),
        'Never Gonna Give You Up',
      );
    });

    test('removes (Remastered) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Imagine (Remastered 2010)'),
        'Imagine',
      );
    });

    test('removes (Acoustic) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Creep (Acoustic)'),
        'Creep',
      );
    });

    test('removes (Deluxe) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Album Title (Deluxe Edition)'),
        'Album Title',
      );
    });

    test('removes (Radio Edit) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (Radio Edit)'),
        'Song Name',
      );
    });

    test('removes (Instrumental) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (Instrumental)'),
        'Song Name',
      );
    });

    test('removes (Sped Up) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (Sped Up)'),
        'Song Name',
      );
    });

    test('removes (Slowed + Reverb) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (Slowed + Reverb)'),
        'Song Name',
      );
    });

    test('removes multiple bracket groups with noise words', () {
      expect(
        TtsService.cleanTitleForSpeech('Song (feat. Artist) [Explicit]'),
        'Song',
      );
    });

    test('case insensitive matching', () {
      expect(
        TtsService.cleanTitleForSpeech('Song (EXPLICIT)'),
        'Song',
      );
      expect(
        TtsService.cleanTitleForSpeech('Song (explicit)'),
        'Song',
      );
      expect(
        TtsService.cleanTitleForSpeech('Song (Explicit)'),
        'Song',
      );
    });

    test('preserves brackets without noise words', () {
      expect(
        TtsService.cleanTitleForSpeech('Concerto No. 5 (Allegro)'),
        'Concerto No. 5 (Allegro)',
      );
    });

    test('preserves subtitle-like brackets', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Title (Part 2)'),
        'Song Title (Part 2)',
      );
    });

    test('handles empty string', () {
      expect(TtsService.cleanTitleForSpeech(''), '');
    });

    test('handles title that is only brackets', () {
      expect(
        TtsService.cleanTitleForSpeech('(Explicit)'),
        '',
      );
    });

    test('removes [Official Music Video] from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song [Official Music Video]'),
        'Song',
      );
    });

    test('removes (Extended) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (Extended Mix)'),
        'Song Name',
      );
    });

    test('removes (Clean) from title', () {
      expect(
        TtsService.cleanTitleForSpeech('Song Name (Clean)'),
        'Song Name',
      );
    });
  });
}
