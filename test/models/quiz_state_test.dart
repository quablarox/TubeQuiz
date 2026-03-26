import 'package:flutter_test/flutter_test.dart';
import 'package:tube_quiz/models/quiz_state.dart';

void main() {
  group('QuizState', () {
    test('default state is idle', () {
      const state = QuizState();
      expect(state.status, QuizStatus.idle);
      expect(state.isServiceRunning, false);
      expect(state.snippetDurationSeconds, 15);
      expect(state.tracksPlayed, 0);
      expect(state.tracksSkipped, 0);
    });

    test('copyWith creates modified copy', () {
      const state = QuizState();
      final modified = state.copyWith(
        status: QuizStatus.playingSnippet,
        snippetDurationSeconds: 30,
        tracksPlayed: 5,
      );

      expect(modified.status, QuizStatus.playingSnippet);
      expect(modified.snippetDurationSeconds, 30);
      expect(modified.tracksPlayed, 5);
      // Unchanged fields retain default values
      expect(modified.isServiceRunning, false);
      expect(modified.tracksSkipped, 0);
    });

    test('copyWith can explicitly set nullable fields to null', () {
      const state = QuizState(
        currentTitle: 'Test Title',
        currentArtist: 'Test Artist',
      );
      final modified = state.copyWith(
        currentTitle: () => null,
        currentArtist: () => null,
      );

      expect(modified.currentTitle, isNull);
      expect(modified.currentArtist, isNull);
    });

    test('copyWith can update nullable fields', () {
      const state = QuizState();
      final modified = state.copyWith(
        currentTitle: () => 'New Title',
        currentArtist: () => 'New Artist',
      );

      expect(modified.currentTitle, 'New Title');
      expect(modified.currentArtist, 'New Artist');
    });

    test('statusLabel returns correct labels', () {
      expect(
        const QuizState(status: QuizStatus.idle).statusLabel,
        'Idle',
      );
      expect(
        const QuizState(status: QuizStatus.waiting).statusLabel,
        'Waiting for track...',
      );
      expect(
        const QuizState(status: QuizStatus.announcing).statusLabel,
        'Announcing track...',
      );
      expect(
        const QuizState(status: QuizStatus.playingSnippet).statusLabel,
        'Playing snippet',
      );
      expect(
        const QuizState(status: QuizStatus.skipping).statusLabel,
        'Skipping track...',
      );
    });

    test('error status includes error message', () {
      const state = QuizState(
        status: QuizStatus.error,
        errorMessage: 'Test error',
      );
      expect(state.statusLabel, 'Error: Test error');
    });
  });
}
