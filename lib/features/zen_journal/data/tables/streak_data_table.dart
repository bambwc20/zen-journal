import 'package:drift/drift.dart';

/// Drift table for streak tracking.
/// Stores current/longest streak, total days, monthly exemptions,
/// and earned badges as JSON array.
class StreakDataEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  IntColumn get totalDays => integer().withDefault(const Constant(0))();
  IntColumn get exemptionsUsedThisMonth => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastEntryDate => dateTime().nullable()();
  TextColumn get badges => text().withDefault(const Constant('[]'))(); // JSON array of badge strings
}
