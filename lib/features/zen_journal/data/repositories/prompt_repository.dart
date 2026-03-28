import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/domain/models/daily_prompt.dart';

part 'prompt_repository.g.dart';

/// Repository for daily writing prompt management.
class PromptRepository {
  final AppDatabase _db;

  PromptRepository(this._db);

  /// Gets today's prompt based on day of year.
  /// Returns the prompt assigned to today's dayOfYear, or the first unused prompt.
  Future<DailyPrompt> getTodayPrompt() async {
    final now = DateTime.now();
    final dayOfYear = _dayOfYear(now);

    // First try to get today's specific prompt
    final todayRow = await (_db.select(_db.dailyPrompts)
          ..where((t) => t.dayOfYear.equals(dayOfYear)))
        .getSingleOrNull();

    if (todayRow != null) {
      return _rowToModel(todayRow);
    }

    // Fallback: get any unused prompt
    return getNextPrompt();
  }

  /// Gets the next available unused prompt.
  Future<DailyPrompt> getNextPrompt() async {
    final row = await (_db.select(_db.dailyPrompts)
          ..where((t) => t.isUsed.equals(false))
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return _rowToModel(row);
    }

    // All prompts used — reset and return the first one
    await (_db.update(_db.dailyPrompts)).write(
      const DailyPromptsCompanion(isUsed: Value(false)),
    );

    final resetRow = await (_db.select(_db.dailyPrompts)..limit(1)).getSingle();
    return _rowToModel(resetRow);
  }

  /// Marks a prompt as used.
  Future<void> markPromptUsed(int promptId) async {
    await (_db.update(_db.dailyPrompts)
          ..where((t) => t.id.equals(promptId)))
        .write(const DailyPromptsCompanion(isUsed: Value(true)));
  }

  /// Gets prompts by category.
  Future<List<DailyPrompt>> getPromptsByCategory(String category) async {
    final rows = await (_db.select(_db.dailyPrompts)
          ..where((t) => t.category.equals(category)))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Seeds the initial 365 prompts from the bundled JSON asset if the table is empty.
  Future<void> seedPromptsIfEmpty() async {
    final count = await _db.select(_db.dailyPrompts).get();
    if (count.isNotEmpty) return;

    final jsonStr = await rootBundle.loadString('assets/prompts.json');
    final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;

    await _db.batch((batch) {
      for (final item in jsonList) {
        batch.insert(
          _db.dailyPrompts,
          DailyPromptsCompanion.insert(
            promptText: item['text'] as String,
            category: item['category'] as String,
            dayOfYear: item['day'] as int,
          ),
        );
      }
    });
  }

  int _dayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  DailyPrompt _rowToModel(dynamic row) {
    return DailyPrompt(
      id: row.id,
      text: row.promptText,
      category: row.category,
      isUsed: row.isUsed,
    );
  }
}

@riverpod
PromptRepository promptRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return PromptRepository(db);
}
