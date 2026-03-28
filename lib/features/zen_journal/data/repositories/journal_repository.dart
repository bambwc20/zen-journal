import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';

part 'journal_repository.g.dart';

/// Repository for journal entry CRUD operations and search.
class JournalRepository {
  final AppDatabase _db;

  JournalRepository(this._db);

  /// Creates a new journal entry and returns its ID.
  Future<int> createEntry(JournalEntry entry) async {
    return await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            content: entry.content,
            plainText: Value(entry.plainText),
            moodLevel: Value(entry.moodLevel),
            photos: Value(jsonEncode(entry.photos)),
            createdAt: Value(entry.createdAt),
            updatedAt: Value(entry.updatedAt),
            wordCount: Value(entry.wordCount),
          ),
        );
  }

  /// Updates an existing journal entry.
  Future<void> updateEntry(JournalEntry entry) async {
    if (entry.id == null) throw ArgumentError('Entry ID cannot be null for update');
    await (_db.update(_db.journalEntries)
          ..where((t) => t.id.equals(entry.id!)))
        .write(
      JournalEntriesCompanion(
        content: Value(entry.content),
        plainText: Value(entry.plainText),
        moodLevel: Value(entry.moodLevel),
        photos: Value(jsonEncode(entry.photos)),
        updatedAt: Value(entry.updatedAt),
        wordCount: Value(entry.wordCount),
      ),
    );
  }

  /// Deletes a journal entry by ID.
  Future<void> deleteEntry(int id) async {
    await (_db.delete(_db.journalEntries)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Gets a single journal entry by ID.
  Future<JournalEntry?> getEntry(int id) async {
    final row = await (_db.select(_db.journalEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Gets entries within a date range, ordered by creation date descending.
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await (_db.select(_db.journalEntries)
          ..where((t) => t.createdAt.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Gets all journal entries ordered by creation date descending.
  Future<List<JournalEntry>> getAllEntries() async {
    final rows = await (_db.select(_db.journalEntries)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Searches entries by plain text content.
  /// Free users: limited to last 30 days (enforced at use case layer).
  Future<List<JournalEntry>> searchEntries(String query) async {
    final rows = await (_db.select(_db.journalEntries)
          ..where((t) => t.plainText.like('%$query%'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Watches all entries as a stream for reactive UI updates.
  Stream<List<JournalEntry>> watchAllEntries() {
    return (_db.select(_db.journalEntries)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  /// Gets the count of entries created today (for free user daily limit check).
  Future<int> getTodayEntryCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final rows = await (_db.select(_db.journalEntries)
          ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay)))
        .get();
    return rows.length;
  }

  JournalEntry _rowToModel(dynamic row) {
    List<String> photos = [];
    try {
      final decoded = jsonDecode(row.photos);
      if (decoded is List) {
        photos = decoded.cast<String>();
      }
    } catch (_) {}

    return JournalEntry(
      id: row.id,
      content: row.content,
      plainText: row.plainText,
      moodLevel: row.moodLevel,
      photos: photos,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      wordCount: row.wordCount,
    );
  }
}

@riverpod
JournalRepository journalRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return JournalRepository(db);
}
