import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/manage_streak.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/streak_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';

class MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late ManageStreak freeUseCase;
  late ManageStreak premiumUseCase;
  late MockStreakRepository mockRepo;

  setUp(() {
    mockRepo = MockStreakRepository();
    freeUseCase = ManageStreak(mockRepo, isPremium: false);
    premiumUseCase = ManageStreak(mockRepo, isPremium: true);
  });

  group('ManageStreak', () {
    group('updateStreak', () {
      test('detects newly earned badges', () async {
        final before = const StreakData(
          currentStreak: 6,
          longestStreak: 6,
          totalDays: 6,
          badges: [],
        );
        final after = const StreakData(
          currentStreak: 7,
          longestStreak: 7,
          totalDays: 7,
          badges: ['7_day'],
        );

        when(() => mockRepo.getStreak()).thenAnswer((_) async => before);
        when(() => mockRepo.updateStreak()).thenAnswer((_) async => after);

        final result = await freeUseCase.updateStreak();

        expect(result.streak.currentStreak, 7);
        expect(result.newBadges, ['7_day']);
      });

      test('returns empty newBadges when no new badge earned', () async {
        final before = const StreakData(
          currentStreak: 7,
          longestStreak: 7,
          totalDays: 7,
          badges: ['7_day'],
        );
        final after = const StreakData(
          currentStreak: 8,
          longestStreak: 8,
          totalDays: 8,
          badges: ['7_day'],
        );

        when(() => mockRepo.getStreak()).thenAnswer((_) async => before);
        when(() => mockRepo.updateStreak()).thenAnswer((_) async => after);

        final result = await freeUseCase.updateStreak();

        expect(result.newBadges, isEmpty);
      });

      test('detects multiple new badges at once', () async {
        // Edge case: if streak jumps (e.g., data correction)
        final before = const StreakData(
          currentStreak: 29,
          longestStreak: 29,
          totalDays: 29,
          badges: ['7_day'],
        );
        final after = const StreakData(
          currentStreak: 30,
          longestStreak: 30,
          totalDays: 30,
          badges: ['7_day', '30_day'],
        );

        when(() => mockRepo.getStreak()).thenAnswer((_) async => before);
        when(() => mockRepo.updateStreak()).thenAnswer((_) async => after);

        final result = await freeUseCase.updateStreak();

        expect(result.newBadges, ['30_day']);
      });
    });

    group('useExemption', () {
      test('free user can use exemption (delegates to repo)', () async {
        when(() => mockRepo.useExemption()).thenAnswer((_) async => true);

        final result = await freeUseCase.useExemption();

        expect(result, isTrue);
        verify(() => mockRepo.useExemption()).called(1);
      });

      test('premium user can use exemption (delegates to repo)', () async {
        when(() => mockRepo.useExemption()).thenAnswer((_) async => true);

        final result = await premiumUseCase.useExemption();

        expect(result, isTrue);
        verify(() => mockRepo.useExemption()).called(1);
      });
    });

    group('canUseExemption', () {
      test('free user can use exemption when none used this month', () async {
        when(() => mockRepo.getStreak()).thenAnswer(
          (_) async => const StreakData(exemptionsUsedThisMonth: 0),
        );

        final result = await freeUseCase.canUseExemption();

        expect(result, isTrue);
      });

      test('free user cannot use exemption when already used this month',
          () async {
        when(() => mockRepo.getStreak()).thenAnswer(
          (_) async => const StreakData(exemptionsUsedThisMonth: 1),
        );

        final result = await freeUseCase.canUseExemption();

        expect(result, isFalse);
      });

      test('premium user can always use exemption', () async {
        when(() => mockRepo.getStreak()).thenAnswer(
          (_) async => const StreakData(exemptionsUsedThisMonth: 5),
        );

        final result = await premiumUseCase.canUseExemption();

        expect(result, isTrue);
      });
    });

    group('getBadgeDisplayName', () {
      test('returns display name for known badge', () {
        expect(ManageStreak.getBadgeDisplayName('7_day'), '7 Day Streak');
        expect(ManageStreak.getBadgeDisplayName('30_day'), '30 Day Streak');
        expect(ManageStreak.getBadgeDisplayName('100_day'), '100 Day Streak');
        expect(ManageStreak.getBadgeDisplayName('365_day'), '365 Day Streak');
      });

      test('returns badge id for unknown badge', () {
        expect(ManageStreak.getBadgeDisplayName('unknown'), 'unknown');
      });
    });
  });
}
