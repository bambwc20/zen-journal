import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/mood_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/streak_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_record.dart';

part 'save_journal_entry.g.dart';

/// Use case for saving a journal entry with auto-save debounce logic.
///
/// Features:
/// - 3-second debounce for auto-save (prevents excessive writes)
/// - Creates or updates entry based on whether ID exists
/// - Saves associated mood record
/// - Updates streak after save
/// - Free user limit: 500 characters (enforced here)
class SaveJournalEntry {
  final JournalRepository _journalRepo;
  final MoodRepository _moodRepo;
  final StreakRepository _streakRepo;

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(seconds: 3);

  /// Maximum character count for free users.
  static const int freeCharLimit = 500;

  /// Maximum entries per day for free users.
  static const int freeDailyEntryLimit = 1;

  SaveJournalEntry(this._journalRepo, this._moodRepo, this._streakRepo);

  /// Saves a journal entry immediately (no debounce).
  /// Used for explicit save actions (e.g., pressing save button).
  ///
  /// Returns the entry ID (new or existing).
  Future<int> saveNow(JournalEntry entry, {MoodRecord? mood}) async {
    _debounceTimer?.cancel();

    final now = DateTime.now();
    final updatedEntry = entry.copyWith(
      updatedAt: now,
      wordCount: _countWords(entry.plainText),
    );

    int entryId;
    if (updatedEntry.id == null) {
      entryId = await _journalRepo.createEntry(updatedEntry);
    } else {
      await _journalRepo.updateEntry(updatedEntry);
      entryId = updatedEntry.id!;
    }

    // Save mood if provided
    if (mood != null) {
      await _moodRepo.saveMood(mood.copyWith(entryId: entryId));
    }

    // Update streak
    await _streakRepo.updateStreak();

    return entryId;
  }

  /// Auto-save with 3-second debounce.
  /// Cancels any pending auto-save and schedules a new one.
  /// Used for real-time typing auto-save.
  void autoSave(
    JournalEntry entry, {
    MoodRecord? mood,
    void Function(int entryId)? onSaved,
    void Function(Object error)? onError,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final id = await saveNow(entry, mood: mood);
        onSaved?.call(id);
      } catch (e) {
        onError?.call(e);
      }
    });
  }

  /// Cancels any pending auto-save timer.
  void cancelAutoSave() {
    _debounceTimer?.cancel();
  }

  /// Validates entry content for free user character limit.
  /// Returns null if valid, or an error message if exceeding limit.
  String? validateFreeUserLimit(String plainText) {
    if (plainText.length > freeCharLimit) {
      return 'Free users are limited to $freeCharLimit characters. '
          'Upgrade to Pro for unlimited writing.';
    }
    return null;
  }

  /// Checks if a free user has reached their daily entry limit.
  /// Returns null if allowed, or an error message if limit reached.
  /// Only applies to new entries (not edits).
  Future<String?> validateDailyEntryLimit() async {
    final todayCount = await _journalRepo.getTodayEntryCount();
    if (todayCount >= freeDailyEntryLimit) {
      return 'Free users can write 1 entry per day. '
          'Upgrade to Pro for unlimited entries.';
    }
    return null;
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

@riverpod
SaveJournalEntry saveJournalEntry(Ref ref) {
  final journalRepo = ref.watch(journalRepositoryProvider);
  final moodRepo = ref.watch(moodRepositoryProvider);
  final streakRepo = ref.watch(streakRepositoryProvider);
  final useCase = SaveJournalEntry(journalRepo, moodRepo, streakRepo);
  ref.onDispose(() => useCase.dispose());
  return useCase;
}
