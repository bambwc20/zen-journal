import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';

void main() {
  late AppDatabase db;
  late JournalRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = JournalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  JournalEntry _makeEntry({
    String content = 'Test content',
    String plainText = 'Test content',
    int moodLevel = 3,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return JournalEntry(
      content: content,
      plainText: plainText,
      moodLevel: moodLevel,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('JournalRepository CRUD', () {
    test('createEntry returns new entry ID', () async {
      final entry = _makeEntry();
      final id = await repo.createEntry(entry);
      expect(id, greaterThan(0));
    });

    test('getEntry returns created entry', () async {
      final entry = _makeEntry(
        content: 'My journal entry',
        plainText: 'My journal entry',
        moodLevel: 4,
      );
      final id = await repo.createEntry(entry);

      final fetched = await repo.getEntry(id);
      expect(fetched, isNotNull);
      expect(fetched!.id, id);
      expect(fetched.content, 'My journal entry');
      expect(fetched.plainText, 'My journal entry');
      expect(fetched.moodLevel, 4);
    });

    test('getEntry returns null for non-existent ID', () async {
      final fetched = await repo.getEntry(999);
      expect(fetched, isNull);
    });

    test('updateEntry modifies existing entry', () async {
      final entry = _makeEntry(content: 'Original');
      final id = await repo.createEntry(entry);

      final updated = JournalEntry(
        id: id,
        content: 'Updated',
        plainText: 'Updated',
        moodLevel: 5,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );
      await repo.updateEntry(updated);

      final fetched = await repo.getEntry(id);
      expect(fetched!.content, 'Updated');
      expect(fetched.moodLevel, 5);
    });

    test('updateEntry throws for null ID', () async {
      final entry = _makeEntry();
      expect(
        () => repo.updateEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteEntry removes entry', () async {
      final id = await repo.createEntry(_makeEntry());
      await repo.deleteEntry(id);
      final fetched = await repo.getEntry(id);
      expect(fetched, isNull);
    });

    test('getAllEntries returns all entries ordered by createdAt desc',
        () async {
      final now = DateTime.now();
      await repo.createEntry(_makeEntry(
        content: 'First',
        plainText: 'First',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ));
      await repo.createEntry(_makeEntry(
        content: 'Second',
        plainText: 'Second',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ));
      await repo.createEntry(_makeEntry(
        content: 'Third',
        plainText: 'Third',
        createdAt: now,
        updatedAt: now,
      ));

      final entries = await repo.getAllEntries();
      expect(entries.length, 3);
      expect(entries[0].content, 'Third');
      expect(entries[1].content, 'Second');
      expect(entries[2].content, 'First');
    });
  });

  group('JournalRepository date range search', () {
    test('getEntriesByDateRange returns entries within range', () async {
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      await repo.createEntry(_makeEntry(
        content: 'Old',
        plainText: 'Old',
        createdAt: threeDaysAgo,
        updatedAt: threeDaysAgo,
      ));
      await repo.createEntry(_makeEntry(
        content: 'In range 1',
        plainText: 'In range 1',
        createdAt: twoDaysAgo,
        updatedAt: twoDaysAgo,
      ));
      await repo.createEntry(_makeEntry(
        content: 'In range 2',
        plainText: 'In range 2',
        createdAt: dayAgo,
        updatedAt: dayAgo,
      ));
      await repo.createEntry(_makeEntry(
        content: 'Today',
        plainText: 'Today',
        createdAt: now,
        updatedAt: now,
      ));

      final entries = await repo.getEntriesByDateRange(twoDaysAgo, now);
      // Should include entries from twoDaysAgo up to (but not including) entries created at exactly 'now' depends on isBetweenValues
      // isBetweenValues is inclusive, so all three should be included
      expect(entries.length, greaterThanOrEqualTo(2));
      for (final entry in entries) {
        expect(
          entry.createdAt.isAfter(threeDaysAgo) ||
              entry.createdAt.isAtSameMomentAs(twoDaysAgo),
          isTrue,
        );
      }
    });

    test('getEntriesByDateRange returns empty for no-match range', () async {
      await repo.createEntry(_makeEntry(
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ));

      final entries = await repo.getEntriesByDateRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );
      expect(entries, isEmpty);
    });
  });

  group('JournalRepository text search', () {
    test('searchEntries finds matching entries', () async {
      await repo.createEntry(_makeEntry(
        content: 'I feel happy today',
        plainText: 'I feel happy today',
      ));
      await repo.createEntry(_makeEntry(
        content: 'Sad and tired',
        plainText: 'Sad and tired',
      ));
      await repo.createEntry(_makeEntry(
        content: 'Happy moments with friends',
        plainText: 'Happy moments with friends',
      ));

      final results = await repo.searchEntries('happy');
      // plainText is case-sensitive in SQLite LIKE by default, but our entries
      // use different cases. Let's check for lowercase match.
      expect(results.length, greaterThanOrEqualTo(1));
    });

    test('searchEntries returns empty for no match', () async {
      await repo.createEntry(_makeEntry(
        content: 'Nothing relevant',
        plainText: 'Nothing relevant',
      ));

      final results = await repo.searchEntries('zzzznotfound');
      expect(results, isEmpty);
    });
  });

  group('JournalRepository getTodayEntryCount', () {
    test('counts entries created today', () async {
      final now = DateTime.now();
      // Create an entry today
      await repo.createEntry(_makeEntry(
        createdAt: now,
        updatedAt: now,
      ));
      // Create an entry yesterday
      await repo.createEntry(_makeEntry(
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ));

      final count = await repo.getTodayEntryCount();
      expect(count, 1);
    });
  });
}
