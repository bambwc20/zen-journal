import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/data/data_sources/ai_api_client.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/ai_reflection.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/weekly_report.dart';

part 'ai_reflection_repository.g.dart';

/// Repository for AI reflection operations.
/// Manages reflection generation, storage, and weekly usage tracking.
class AiReflectionRepository {
  final AppDatabase _db;
  final AiApiClient _aiClient;

  AiReflectionRepository(this._db, this._aiClient);

  /// Generates an AI reflection for a journal entry.
  /// Fetches context from the last 7 days of entries and calls the AI API.
  Future<AiReflection> generateReflection(int entryId) async {
    // Get the target entry
    final entry = await (_db.select(_db.journalEntries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();

    if (entry == null) {
      throw ArgumentError('Entry with id $entryId not found');
    }

    // Get last 7 days of entries for context window
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final contextEntries = await (_db.select(_db.journalEntries)
          ..where((t) => t.createdAt.isBetweenValues(sevenDaysAgo, now))
          ..where((t) => t.id.isNotValue(entryId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();

    // Build context strings
    final contextTexts = contextEntries
        .map((e) => '${e.createdAt.toIso8601String().substring(0, 10)}: ${e.plainText}')
        .toList();

    // Call AI API
    final response = await _aiClient.getReflection(
      currentEntry: entry.plainText,
      contextEntries: contextTexts,
      moodLevel: entry.moodLevel,
    );

    // Save to database
    final id = await _db.into(_db.aiReflections).insert(
          AiReflectionsCompanion.insert(
            entryId: entryId,
            emotionAnalysis: response.emotionAnalysis,
            patternInsight: response.patternInsight,
            actionSuggestion: response.actionSuggestion,
          ),
        );

    // Update usage count for current week
    await _incrementWeeklyUsage();

    return AiReflection(
      id: id,
      entryId: entryId,
      emotionAnalysis: response.emotionAnalysis,
      patternInsight: response.patternInsight,
      actionSuggestion: response.actionSuggestion,
      createdAt: DateTime.now(),
    );
  }

  /// Gets the existing reflection for a journal entry, if any.
  Future<AiReflection?> getReflectionForEntry(int entryId) async {
    final row = await (_db.select(_db.aiReflections)
          ..where((t) => t.entryId.equals(entryId)))
        .getSingleOrNull();
    return row != null ? _reflectionRowToModel(row) : null;
  }

  /// Gets the remaining free AI reflections for the current week.
  /// Free users get 2 per week.
  Future<int> getRemainingFreeReflections() async {
    final weekStart = _getWeekStart(DateTime.now());
    final row = await (_db.select(_db.aiUsageEntries)
          ..where((t) => t.weekStart.equals(weekStart)))
        .getSingleOrNull();

    if (row == null) {
      return 2; // No usage this week
    }

    final remaining = row.maxFree - row.reflectionsUsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Gets a weekly AI report for premium users.
  /// Returns null if not enough entries exist for the week.
  Future<WeeklyReport?> getWeeklyReport(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Get entries for the week
    final entries = await (_db.select(_db.journalEntries)
          ..where((t) => t.createdAt.isBetweenValues(weekStart, weekEnd))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();

    if (entries.isEmpty) return null;

    final entryTexts = entries
        .map((e) => '${e.createdAt.toIso8601String().substring(0, 10)}: ${e.plainText}')
        .toList();

    final moodLevels = entries.map((e) => e.moodLevel).toList();

    // Call AI API for weekly report
    final report = await _aiClient.getWeeklyReport(
      entries: entryTexts,
      moodLevels: moodLevels,
    );

    return WeeklyReport(
      weekStart: weekStart,
      summary: report.summary,
      moodTrend: report.moodTrend,
      keyInsights: report.keyInsights,
      totalEntries: entries.length,
    );
  }

  /// Increments the weekly usage counter.
  Future<void> _incrementWeeklyUsage() async {
    final weekStart = _getWeekStart(DateTime.now());
    final existing = await (_db.select(_db.aiUsageEntries)
          ..where((t) => t.weekStart.equals(weekStart)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.aiUsageEntries).insert(
            AiUsageEntriesCompanion.insert(
              weekStart: weekStart,
              reflectionsUsed: const Value(1),
            ),
          );
    } else {
      await (_db.update(_db.aiUsageEntries)
            ..where((t) => t.weekStart.equals(weekStart)))
          .write(AiUsageEntriesCompanion(
        reflectionsUsed: Value(existing.reflectionsUsed + 1),
      ));
    }
  }

  /// Gets the start of the current ISO week (Monday).
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    final monday = date.subtract(Duration(days: weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  AiReflection _reflectionRowToModel(dynamic row) {
    return AiReflection(
      id: row.id,
      entryId: row.entryId,
      emotionAnalysis: row.emotionAnalysis,
      patternInsight: row.patternInsight,
      actionSuggestion: row.actionSuggestion,
      createdAt: row.createdAt,
    );
  }
}

@riverpod
AiReflectionRepository aiReflectionRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final aiClient = ref.watch(aiApiClientProvider);
  return AiReflectionRepository(db, aiClient);
}
