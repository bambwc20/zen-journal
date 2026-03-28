import 'package:drift/drift.dart';

/// Drift table for tags.
/// Stores predefined (20 default) and custom tags with usage counts.
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
}
