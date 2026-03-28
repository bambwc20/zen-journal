import 'package:drift/drift.dart';

/// Drift table for daily writing prompts.
/// Pool of 365 prompts, categorized and tracked for usage.
class DailyPrompts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get promptText => text()();
  TextColumn get category => text()(); // self_reflection, gratitude, goals, relationships, creativity
  BoolColumn get isUsed => boolean().withDefault(const Constant(false))();
  IntColumn get dayOfYear => integer()(); // 1-365
}
