import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/save_journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/mood_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/streak_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_record.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';

class MockJournalRepository extends Mock implements JournalRepository {}

class MockMoodRepository extends Mock implements MoodRepository {}

class MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late SaveJournalEntry useCase;
  late MockJournalRepository mockJournalRepo;
  late MockMoodRepository mockMoodRepo;
  late MockStreakRepository mockStreakRepo;

  setUp(() {
    mockJournalRepo = MockJournalRepository();
    mockMoodRepo = MockMoodRepository();
    mockStreakRepo = MockStreakRepository();
    useCase = SaveJournalEntry(mockJournalRepo, mockMoodRepo, mockStreakRepo);
  });

  tearDown(() {
    useCase.dispose();
  });

  setUpAll(() {
    registerFallbackValue(JournalEntry(
      content: '',
      plainText: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    registerFallbackValue(MoodRecord(
      level: 3,
      date: DateTime.now(),
    ));
  });

  group('SaveJournalEntry', () {
    final now = DateTime.now();

    group('saveNow', () {
      test('creates a new entry when id is null', () async {
        final entry = JournalEntry(
          content: 'Test content',
          plainText: 'Test content',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockJournalRepo.createEntry(any()))
            .thenAnswer((_) async => 1);
        when(() => mockStreakRepo.updateStreak())
            .thenAnswer((_) async => const StreakData());

        final id = await useCase.saveNow(entry);

        expect(id, 1);
        verify(() => mockJournalRepo.createEntry(any())).called(1);
        verifyNever(() => mockJournalRepo.updateEntry(any()));
        verify(() => mockStreakRepo.updateStreak()).called(1);
      });

      test('updates an existing entry when id is not null', () async {
        final entry = JournalEntry(
          id: 42,
          content: 'Updated content',
          plainText: 'Updated content',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockJournalRepo.updateEntry(any()))
            .thenAnswer((_) async {});
        when(() => mockStreakRepo.updateStreak())
            .thenAnswer((_) async => const StreakData());

        final id = await useCase.saveNow(entry);

        expect(id, 42);
        verifyNever(() => mockJournalRepo.createEntry(any()));
        verify(() => mockJournalRepo.updateEntry(any())).called(1);
        verify(() => mockStreakRepo.updateStreak()).called(1);
      });

      test('saves mood when provided', () async {
        final entry = JournalEntry(
          content: 'Content',
          plainText: 'Content',
          createdAt: now,
          updatedAt: now,
        );
        final mood = MoodRecord(
          level: 4,
          tags: ['happy'],
          date: now,
        );

        when(() => mockJournalRepo.createEntry(any()))
            .thenAnswer((_) async => 5);
        when(() => mockMoodRepo.saveMood(any()))
            .thenAnswer((_) async => 1);
        when(() => mockStreakRepo.updateStreak())
            .thenAnswer((_) async => const StreakData());

        await useCase.saveNow(entry, mood: mood);

        verify(() => mockMoodRepo.saveMood(any())).called(1);
      });

      test('does not save mood when not provided', () async {
        final entry = JournalEntry(
          content: 'Content',
          plainText: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockJournalRepo.createEntry(any()))
            .thenAnswer((_) async => 1);
        when(() => mockStreakRepo.updateStreak())
            .thenAnswer((_) async => const StreakData());

        await useCase.saveNow(entry);

        verifyNever(() => mockMoodRepo.saveMood(any()));
      });

      test('computes word count from plainText', () async {
        final entry = JournalEntry(
          content: 'Hello world this is a test',
          plainText: 'Hello world this is a test',
          createdAt: now,
          updatedAt: now,
        );

        JournalEntry? capturedEntry;
        when(() => mockJournalRepo.createEntry(any()))
            .thenAnswer((invocation) {
          capturedEntry = invocation.positionalArguments[0] as JournalEntry;
          return Future.value(1);
        });
        when(() => mockStreakRepo.updateStreak())
            .thenAnswer((_) async => const StreakData());

        await useCase.saveNow(entry);

        expect(capturedEntry!.wordCount, 6);
      });
    });

    group('validateFreeUserLimit', () {
      test('returns null for text within 500 character limit', () {
        final text = 'A' * 500;
        final result = useCase.validateFreeUserLimit(text);
        expect(result, isNull);
      });

      test('returns error message for text exceeding 500 characters', () {
        final text = 'A' * 501;
        final result = useCase.validateFreeUserLimit(text);
        expect(result, isNotNull);
        expect(result, contains('500'));
        expect(result, contains('Upgrade'));
      });

      test('returns null for empty text', () {
        final result = useCase.validateFreeUserLimit('');
        expect(result, isNull);
      });
    });

    group('autoSave debounce', () {
      test('debounces calls with 3-second delay', () {
        fakeAsync((async) {
          final entry = JournalEntry(
            content: 'Auto save test',
            plainText: 'Auto save test',
            createdAt: now,
            updatedAt: now,
          );

          when(() => mockJournalRepo.createEntry(any()))
              .thenAnswer((_) async => 1);
          when(() => mockStreakRepo.updateStreak())
              .thenAnswer((_) async => const StreakData());

          bool saved = false;
          useCase.autoSave(
            entry,
            onSaved: (id) => saved = true,
          );

          // Should not have saved yet (within debounce period)
          verifyNever(() => mockJournalRepo.createEntry(any()));

          // Advance past debounce duration
          async.elapse(const Duration(seconds: 4));

          verify(() => mockJournalRepo.createEntry(any())).called(1);
          expect(saved, isTrue);
        });
      });

      test('cancels previous auto-save when called again', () {
        fakeAsync((async) {
          final entry1 = JournalEntry(
            content: 'First',
            plainText: 'First',
            createdAt: now,
            updatedAt: now,
          );
          final entry2 = JournalEntry(
            content: 'Second',
            plainText: 'Second',
            createdAt: now,
            updatedAt: now,
          );

          when(() => mockJournalRepo.createEntry(any()))
              .thenAnswer((_) async => 1);
          when(() => mockStreakRepo.updateStreak())
              .thenAnswer((_) async => const StreakData());

          useCase.autoSave(entry1);

          // Call again before debounce triggers
          async.elapse(const Duration(seconds: 1));
          useCase.autoSave(entry2);

          // Advance past debounce duration
          async.elapse(const Duration(seconds: 4));

          // Only one save should have occurred (the second one)
          verify(() => mockJournalRepo.createEntry(any())).called(1);
        });
      });

      test('cancelAutoSave prevents pending save', () {
        fakeAsync((async) {
          final entry = JournalEntry(
            content: 'Cancel me',
            plainText: 'Cancel me',
            createdAt: now,
            updatedAt: now,
          );

          useCase.autoSave(entry);
          useCase.cancelAutoSave();

          async.elapse(const Duration(seconds: 4));

          verifyNever(() => mockJournalRepo.createEntry(any()));
        });
      });
    });
  });
}
