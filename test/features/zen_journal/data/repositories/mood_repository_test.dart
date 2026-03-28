import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/mood_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_record.dart';

void main() {
  late AppDatabase db;
  late MoodRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MoodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MoodRepository', () {
    group('saveMood and getMoodByDate', () {
      test('saves and retrieves mood record by date', () async {
        final now = DateTime.now();
        final mood = MoodRecord(
          level: 4,
          tags: ['grateful', 'calm'],
          date: now,
        );

        final id = await repo.saveMood(mood);
        expect(id, greaterThan(0));

        final fetched = await repo.getMoodByDate(now);
        expect(fetched, isNotNull);
        expect(fetched!.level, 4);
        expect(fetched.tags, ['grateful', 'calm']);
      });

      test('getMoodByDate returns null for date with no mood', () async {
        final result =
            await repo.getMoodByDate(DateTime(2025, 1, 1));
        expect(result, isNull);
      });

      test('saves mood with entryId', () async {
        final mood = MoodRecord(
          level: 5,
          tags: ['happy'],
          date: DateTime.now(),
          entryId: 42,
        );

        await repo.saveMood(mood);
        final fetched = await repo.getMoodByDate(mood.date);
        expect(fetched, isNotNull);
        expect(fetched!.entryId, 42);
      });
    });

    group('getMoodsByDateRange', () {
      test('returns moods within date range ordered by date desc', () async {
        final day1 = DateTime(2026, 3, 15, 10);
        final day2 = DateTime(2026, 3, 16, 10);
        final day3 = DateTime(2026, 3, 17, 10);

        await repo.saveMood(MoodRecord(level: 2, date: day1));
        await repo.saveMood(MoodRecord(level: 3, date: day2));
        await repo.saveMood(MoodRecord(level: 5, date: day3));

        final results = await repo.getMoodsByDateRange(
          DateTime(2026, 3, 15),
          DateTime(2026, 3, 18),
        );

        expect(results.length, 3);
        // Ordered by date desc
        expect(results[0].level, 5);
        expect(results[1].level, 3);
        expect(results[2].level, 2);
      });

      test('returns empty list for date range with no moods', () async {
        final results = await repo.getMoodsByDateRange(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );
        expect(results, isEmpty);
      });
    });

    group('getMoodStats', () {
      test('computes correct statistics', () async {
        final day1 = DateTime(2026, 3, 15, 10);
        final day2 = DateTime(2026, 3, 16, 10);
        final day3 = DateTime(2026, 3, 17, 10);

        await repo.saveMood(MoodRecord(
          level: 2,
          tags: ['stressed', 'tired'],
          date: day1,
        ));
        await repo.saveMood(MoodRecord(
          level: 4,
          tags: ['grateful'],
          date: day2,
        ));
        await repo.saveMood(MoodRecord(
          level: 4,
          tags: ['grateful', 'calm'],
          date: day3,
        ));

        final stats = await repo.getMoodStats(
          DateTime(2026, 3, 15),
          DateTime(2026, 3, 18),
        );

        expect(stats.totalEntries, 3);
        // Average: (2 + 4 + 4) / 3 = 3.33...
        expect(stats.averageMood, closeTo(3.33, 0.01));

        // Distribution
        expect(stats.moodDistribution[2], 1);
        expect(stats.moodDistribution[4], 2);

        // Tag frequency
        expect(stats.tagFrequency['grateful'], 2);
        expect(stats.tagFrequency['stressed'], 1);
        expect(stats.tagFrequency['tired'], 1);
        expect(stats.tagFrequency['calm'], 1);
      });

      test('returns empty stats for no data', () async {
        final stats = await repo.getMoodStats(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 31),
        );

        expect(stats.totalEntries, 0);
        expect(stats.averageMood, 0.0);
        expect(stats.moodDistribution, isEmpty);
        expect(stats.tagFrequency, isEmpty);
      });
    });
  });
}
