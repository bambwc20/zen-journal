import 'package:drift/drift.dart';

/// Manages database schema migrations.
/// Add migration steps here when incrementing schemaVersion.
class MigrationHelper {
  static Future<void> migrate(Migrator m, int from, int to) async {
    for (var target = from + 1; target <= to; target++) {
      switch (target) {
        // case 2:
        //   await m.addColumn(table, column);
        //   break;
        default:
          break;
      }
    }
  }
}
