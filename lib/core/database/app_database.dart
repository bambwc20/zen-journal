import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

// ZenJournal tables
import 'package:flutter_boilerplate/features/zen_journal/data/tables/journal_entries_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/mood_records_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/tags_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/entry_tags_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/streak_data_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/daily_prompts_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/ai_reflections_table.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/tables/ai_usage_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  JournalEntries,
  MoodRecords,
  Tags,
  EntryTags,
  StreakDataEntries,
  DailyPrompts,
  AiReflections,
  AiUsageEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Add migrations here
      },
    );
  }
}

/// Encryption key management for SQLCipher.
const _kEncryptionKeyStorageKey = 'zen_journal_db_key';
const _secureStorage = FlutterSecureStorage();

/// Generates or retrieves the database encryption passphrase.
Future<String> _getOrCreateEncryptionKey() async {
  var key = await _secureStorage.read(key: _kEncryptionKeyStorageKey);
  if (key == null) {
    key = DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
        Object().hashCode.toRadixString(36);
    await _secureStorage.write(key: _kEncryptionKeyStorageKey, value: key);
  }
  return key;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Configure sqlite3 to use SQLCipher library instead of sqlite3
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zen_journal.sqlite'));
    final encryptionKey = await _getOrCreateEncryptionKey();

    // Use NativeDatabase (not createInBackground) so the SQLCipher
    // library override applies in the same isolate.
    return NativeDatabase(
      file,
      setup: (db) {
        // SQLCipher: PRAGMA key must be the first statement after opening
        db.execute("PRAGMA key = '$encryptionKey';");
      },
    );
  });
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}
