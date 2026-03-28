import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/save_journal_entry.dart';

part 'journal_providers.g.dart';

/// Watches all journal entries as a reactive stream.
@riverpod
Stream<List<JournalEntry>> journalEntriesStream(Ref ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.watchAllEntries();
}

/// Gets all journal entries (non-stream, for one-time reads).
@riverpod
Future<List<JournalEntry>> allJournalEntries(Ref ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getAllEntries();
}

/// Gets a single journal entry by ID.
@riverpod
Future<JournalEntry?> journalEntry(Ref ref, int id) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getEntry(id);
}

/// Gets entries for a specific date range.
@riverpod
Future<List<JournalEntry>> entriesByDateRange(
  Ref ref,
  DateTime start,
  DateTime end,
) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getEntriesByDateRange(start, end);
}

/// Manages the current search query for journal entries.
@riverpod
class JournalSearchQuery extends _$JournalSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Searches journal entries based on the current search query.
@riverpod
Future<List<JournalEntry>> searchJournalEntries(Ref ref) async {
  final query = ref.watch(journalSearchQueryProvider);
  if (query.isEmpty) return [];
  final repo = ref.watch(journalRepositoryProvider);
  return repo.searchEntries(query);
}

/// Gets today's entry count (for free user daily limit check).
@riverpod
Future<int> todayEntryCount(Ref ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getTodayEntryCount();
}

/// Manages the currently editing journal entry state.
@riverpod
class CurrentEditingEntry extends _$CurrentEditingEntry {
  @override
  JournalEntry? build() => null;

  void setEntry(JournalEntry entry) {
    state = entry;
  }

  void updateContent(String content, String plainText) {
    if (state == null) return;
    state = state!.copyWith(
      content: content,
      plainText: plainText,
      wordCount: plainText.trim().isEmpty
          ? 0
          : plainText.trim().split(RegExp(r'\s+')).length,
      updatedAt: DateTime.now(),
    );
  }

  void updateMood(int moodLevel) {
    if (state == null) return;
    state = state!.copyWith(moodLevel: moodLevel);
  }

  void updatePhotos(List<String> photos) {
    if (state == null) return;
    state = state!.copyWith(photos: photos);
  }

  void clear() {
    state = null;
  }

  /// Creates a new blank entry for editing.
  void createNew() {
    final now = DateTime.now();
    state = JournalEntry(
      content: '',
      plainText: '',
      moodLevel: 3,
      photos: [],
      createdAt: now,
      updatedAt: now,
      wordCount: 0,
    );
  }
}

/// Provides the SaveJournalEntry use case (already defined in use_cases).
/// Re-exported here for convenience. Use saveJournalEntryProvider from
/// domain/use_cases/save_journal_entry.dart directly.
