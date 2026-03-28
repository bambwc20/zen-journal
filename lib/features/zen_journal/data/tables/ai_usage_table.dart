import 'package:drift/drift.dart';

/// Drift table for tracking AI reflection usage per week.
/// Free users get 2 reflections per week (maxFree=2).
class AiUsageEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get weekStart => dateTime()();
  IntColumn get reflectionsUsed => integer().withDefault(const Constant(0))();
  IntColumn get maxFree => integer().withDefault(const Constant(2))();
}
