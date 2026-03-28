import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_record.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_stats.dart';

part 'mood_repository.g.dart';

/// Repository for mood record CRUD and statistics computation.
class MoodRepository {
  final AppDatabase _db;

  MoodRepository(this._db);

  /// Saves a mood record and returns its ID.
  Future<int> saveMood(MoodRecord mood) async {
    return await _db.into(_db.moodRecords).insert(
          MoodRecordsCompanion.insert(
            level: mood.level,
            tags: Value(jsonEncode(mood.tags)),
            date: mood.date,
            entryId: Value(mood.entryId),
          ),
        );
  }

  /// Gets the mood record for a specific date.
  Future<MoodRecord?> getMoodByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final row = await (_db.select(_db.moodRecords)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay)))
        .getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Gets mood records within a date range, ordered by date descending.
  Future<List<MoodRecord>> getMoodsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await (_db.select(_db.moodRecords)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Computes aggregated mood statistics for a date range.
  Future<MoodStats> getMoodStats(DateTime start, DateTime end) async {
    final moods = await getMoodsByDateRange(start, end);

    if (moods.isEmpty) {
      return const MoodStats();
    }

    // Calculate average mood
    final totalMood = moods.fold<num>(0, (sum, m) => sum + m.level).toInt();
    final averageMood = totalMood / moods.length;

    // Calculate mood distribution
    final moodDistribution = <int, int>{};
    for (final mood in moods) {
      moodDistribution[mood.level] = (moodDistribution[mood.level] ?? 0) + 1;
    }

    // Calculate tag frequency
    final tagFrequency = <String, int>{};
    for (final mood in moods) {
      for (final tag in mood.tags) {
        tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
      }
    }

    return MoodStats(
      averageMood: averageMood,
      moodDistribution: moodDistribution,
      tagFrequency: tagFrequency,
      totalEntries: moods.length,
    );
  }

  /// Watches mood records for a date range as a stream.
  Stream<List<MoodRecord>> watchMoodsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (_db.select(_db.moodRecords)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  MoodRecord _rowToModel(dynamic row) {
    List<String> tags = [];
    try {
      final decoded = jsonDecode(row.tags);
      if (decoded is List) {
        tags = decoded.cast<String>();
      }
    } catch (_) {}

    return MoodRecord(
      id: row.id,
      level: row.level,
      tags: tags,
      date: row.date,
      entryId: row.entryId,
    );
  }
}

@riverpod
MoodRepository moodRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return MoodRepository(db);
}
