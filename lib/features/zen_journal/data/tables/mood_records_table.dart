import 'package:drift/drift.dart';
import 'journal_entries_table.dart';

/// Drift table for mood records.
/// Tracks mood level (1-5), associated tags, and links to a journal entry.
class MoodRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get level => integer()(); // 1-5 scale
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array of tag strings
  DateTimeColumn get date => dateTime()();
  IntColumn get entryId => integer().nullable().references(JournalEntries, #id)();
}
