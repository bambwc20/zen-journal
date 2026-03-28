import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/get_ai_reflection.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/ai_reflection_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/ai_reflection.dart';

class MockAiReflectionRepository extends Mock
    implements AiReflectionRepository {}

void main() {
  late GetAiReflection freeUseCase;
  late GetAiReflection premiumUseCase;
  late MockAiReflectionRepository mockRepo;

  setUp(() {
    mockRepo = MockAiReflectionRepository();
    freeUseCase = GetAiReflection(mockRepo, isPremium: false);
    premiumUseCase = GetAiReflection(mockRepo, isPremium: true);
  });

  final testReflection = AiReflection(
    id: 1,
    entryId: 10,
    emotionAnalysis: 'You seem happy',
    patternInsight: 'Positive trend',
    actionSuggestion: 'Keep it up',
    createdAt: DateTime.now(),
  );

  group('GetAiReflection', () {
    group('execute', () {
      test('returns cached reflection if one exists', () async {
        when(() => mockRepo.getReflectionForEntry(10))
            .thenAnswer((_) async => testReflection);

        final result = await freeUseCase.execute(10);

        expect(result, testReflection);
        verify(() => mockRepo.getReflectionForEntry(10)).called(1);
        verifyNever(() => mockRepo.generateReflection(any()));
        verifyNever(() => mockRepo.getRemainingFreeReflections());
      });

      test('free user: generates reflection when within limit', () async {
        when(() => mockRepo.getReflectionForEntry(10))
            .thenAnswer((_) async => null);
        when(() => mockRepo.getRemainingFreeReflections())
            .thenAnswer((_) async => 1);
        when(() => mockRepo.generateReflection(10))
            .thenAnswer((_) async => testReflection);

        final result = await freeUseCase.execute(10);

        expect(result, testReflection);
        verify(() => mockRepo.getRemainingFreeReflections()).called(1);
        verify(() => mockRepo.generateReflection(10)).called(1);
      });

      test('free user: throws when weekly limit reached (0 remaining)',
          () async {
        when(() => mockRepo.getReflectionForEntry(10))
            .thenAnswer((_) async => null);
        when(() => mockRepo.getRemainingFreeReflections())
            .thenAnswer((_) async => 0);

        expect(
          () => freeUseCase.execute(10),
          throwsA(isA<AiReflectionLimitReachedException>()),
        );
      });

      test('premium user: skips limit check and generates reflection',
          () async {
        when(() => mockRepo.getReflectionForEntry(10))
            .thenAnswer((_) async => null);
        when(() => mockRepo.generateReflection(10))
            .thenAnswer((_) async => testReflection);

        final result = await premiumUseCase.execute(10);

        expect(result, testReflection);
        verifyNever(() => mockRepo.getRemainingFreeReflections());
        verify(() => mockRepo.generateReflection(10)).called(1);
      });
    });

    group('getRemainingFree', () {
      test('free user: returns remaining count from repo', () async {
        when(() => mockRepo.getRemainingFreeReflections())
            .thenAnswer((_) async => 1);

        final result = await freeUseCase.getRemainingFree();

        expect(result, 1);
      });

      test('premium user: returns -1 (unlimited)', () async {
        final result = await premiumUseCase.getRemainingFree();

        expect(result, -1);
        verifyNever(() => mockRepo.getRemainingFreeReflections());
      });
    });

    group('getWeeklyReport', () {
      test('free user: returns null', () async {
        final result =
            await freeUseCase.getWeeklyReport(DateTime(2026, 3, 16));

        expect(result, isNull);
      });

      test('premium user: delegates to repo', () async {
        when(() => mockRepo.getWeeklyReport(any()))
            .thenAnswer((_) async => null);

        await premiumUseCase.getWeeklyReport(DateTime(2026, 3, 16));

        verify(() => mockRepo.getWeeklyReport(any())).called(1);
      });
    });

    group('AiReflectionLimitReachedException', () {
      test('has correct toString', () {
        const exception = AiReflectionLimitReachedException(
          usedCount: 2,
          maxFree: 2,
        );
        expect(exception.toString(), contains('2/2'));
        expect(exception.toString(), contains('Upgrade'));
      });
    });
  });
}
