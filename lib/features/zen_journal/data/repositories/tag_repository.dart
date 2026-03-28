import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/domain/models/tag.dart';

part 'tag_repository.g.dart';

/// Repository for tag CRUD and entry-tag association management.
class TagRepository {
  final AppDatabase _db;

  TagRepository(this._db);

  /// Creates a new tag and returns its ID.
  Future<int> createTag(Tag tag) async {
    return await _db.into(_db.tags).insert(
          TagsCompanion.insert(
            name: tag.name,
            isCustom: Value(tag.isCustom),
            usageCount: Value(tag.usageCount),
          ),
        );
  }

  /// Gets all tags ordered by usage count descending.
  Future<List<Tag>> getAllTags() async {
    final rows = await (_db.select(_db.tags)
          ..orderBy([
            (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Gets tags associated with a specific journal entry.
  Future<List<Tag>> getTagsForEntry(int entryId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(
        _db.entryTags,
        _db.entryTags.tagId.equalsExp(_db.tags.id),
      ),
    ])
      ..where(_db.entryTags.entryId.equals(entryId));

    final rows = await query.get();
    return rows.map((row) => _rowToModel(row.readTable(_db.tags))).toList();
  }

  /// Sets tags for a journal entry (replaces existing associations).
  /// Updates usage counts accordingly.
  Future<void> setTagsForEntry(int entryId, List<int> tagIds) async {
    await _db.transaction(() async {
      // Get current tags for decrement
      final currentTags = await getTagsForEntry(entryId);
      for (final tag in currentTags) {
        if (tag.id != null) {
          await (_db.update(_db.tags)..where((t) => t.id.equals(tag.id!)))
              .write(TagsCompanion(
            usageCount: Value(tag.usageCount > 0 ? tag.usageCount - 1 : 0),
          ));
        }
      }

      // Remove existing associations
      await (_db.delete(_db.entryTags)
            ..where((t) => t.entryId.equals(entryId)))
          .go();

      // Insert new associations and increment usage counts
      for (final tagId in tagIds) {
        await _db.into(_db.entryTags).insert(
              EntryTagsCompanion.insert(
                entryId: entryId,
                tagId: tagId,
              ),
            );
        // Increment usage count
        await _db.customStatement(
          'UPDATE tags SET usage_count = usage_count + 1 WHERE id = ?',
          [tagId],
        );
      }
    });
  }

  /// Deletes a custom tag by ID.
  Future<void> deleteTag(int id) async {
    await _db.transaction(() async {
      // Remove all entry associations
      await (_db.delete(_db.entryTags)..where((t) => t.tagId.equals(id))).go();
      // Delete the tag
      await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Seeds the 20 predefined tags if the table is empty.
  Future<void> seedDefaultTags() async {
    final existingCount = await _db.select(_db.tags).get();
    if (existingCount.isNotEmpty) return;

    const defaultTags = [
      'Grateful', 'Happy', 'Calm', 'Excited', 'Hopeful',
      'Anxious', 'Stressed', 'Sad', 'Angry', 'Tired',
      'Productive', 'Creative', 'Social', 'Lonely', 'Motivated',
      'Relaxed', 'Confused', 'Confident', 'Nostalgic', 'Inspired',
    ];

    for (final tagName in defaultTags) {
      await _db.into(_db.tags).insert(
            TagsCompanion.insert(
              name: tagName,
              isCustom: const Value(false),
            ),
          );
    }
  }

  Tag _rowToModel(dynamic row) {
    return Tag(
      id: row.id,
      name: row.name,
      isCustom: row.isCustom,
      usageCount: row.usageCount,
    );
  }
}

@riverpod
TagRepository tagRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TagRepository(db);
}
