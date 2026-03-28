import 'package:drift/drift.dart';
import 'journal_entries_table.dart';
import 'tags_table.dart';

/// Join table linking journal entries to tags (many-to-many).
class EntryTags extends Table {
  IntColumn get entryId => integer().references(JournalEntries, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {entryId, tagId};
}
