import 'package:drift/drift.dart';
import 'journal_entries_table.dart';

/// Drift table for AI-generated reflections.
/// Stores emotion analysis, pattern insight, and action suggestion
/// linked to a journal entry.
class AiReflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(JournalEntries, #id)();
  TextColumn get emotionAnalysis => text()();
  TextColumn get patternInsight => text()();
  TextColumn get actionSuggestion => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
