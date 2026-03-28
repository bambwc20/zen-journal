import 'package:drift/drift.dart';

/// Drift table for journal entries.
/// Stores rich text content as Delta JSON, plain text for search,
/// mood level (1-5), photo paths as JSON array, and word count.
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()(); // Delta JSON from flutter_quill
  TextColumn get plainText => text().withDefault(const Constant(''))();
  IntColumn get moodLevel => integer().withDefault(const Constant(3))();
  TextColumn get photos => text().withDefault(const Constant('[]'))(); // JSON array of file paths
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
}
