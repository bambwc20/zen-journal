import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/database/app_database.dart'
    hide JournalEntry, MoodRecord, Tag, DailyPrompt, AiReflection;
import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';

part 'streak_repository.g.dart';

/// Repository for streak data management.
/// Handles streak calculation, badge assignment, and exemption tracking.
class StreakRepository {
  final AppDatabase _db;

  StreakRepository(this._db);

  /// Gets current streak data. Creates initial record if none exists.
  Future<StreakData> getStreak() async {
    final rows = await _db.select(_db.streakDataEntries).get();
    if (rows.isEmpty) {
      // Create initial streak record
      await _db.into(_db.streakDataEntries).insert(
            StreakDataEntriesCompanion.insert(),
          );
      return const StreakData();
    }
    return _rowToModel(rows.first);
  }

  /// Updates the streak based on today's entry.
  /// Returns the updated streak data.
  Future<StreakData> updateStreak() async {
    final current = await getStreak();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already recorded today
    if (current.lastEntryDate != null) {
      final lastDate = DateTime(
        current.lastEntryDate!.year,
        current.lastEntryDate!.month,
        current.lastEntryDate!.day,
      );
      if (lastDate == today) {
        return current; // Already recorded today
      }
    }

    int newStreak = current.currentStreak;
    int newLongest = current.longestStreak;
    int newTotal = current.totalDays + 1;
    List<String> newBadges = List<String>.from(current.badges);

    // Reset monthly exemptions if new month
    int exemptions = current.exemptionsUsedThisMonth;
    if (current.lastEntryDate != null &&
        current.lastEntryDate!.month != now.month) {
      exemptions = 0;
    }

    // Calculate streak continuity
    if (current.lastEntryDate != null) {
      final lastDate = DateTime(
        current.lastEntryDate!.year,
        current.lastEntryDate!.month,
        current.lastEntryDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        // Consecutive day
        newStreak += 1;
      } else if (difference == 2 && exemptions < 1) {
        // Missed one day but no exemption used — streak broken unless exemption was applied
        newStreak = 1;
      } else if (difference > 1) {
        // Streak broken
        newStreak = 1;
      }
    } else {
      // First entry ever
      newStreak = 1;
    }

    // Update longest streak
    if (newStreak > newLongest) {
      newLongest = newStreak;
    }

    // Check for new badges
    const milestones = {
      7: '7_day',
      30: '30_day',
      100: '100_day',
      365: '365_day',
    };
    for (final entry in milestones.entries) {
      if (newStreak >= entry.key && !newBadges.contains(entry.value)) {
        newBadges.add(entry.value);
      }
    }

    // Persist updated streak
    final updated = StreakData(
      currentStreak: newStreak,
      longestStreak: newLongest,
      totalDays: newTotal,
      exemptionsUsedThisMonth: exemptions,
      lastEntryDate: today,
      badges: newBadges,
    );

    await (_db.update(_db.streakDataEntries))
        .write(
      StreakDataEntriesCompanion(
        currentStreak: Value(updated.currentStreak),
        longestStreak: Value(updated.longestStreak),
        totalDays: Value(updated.totalDays),
        exemptionsUsedThisMonth: Value(updated.exemptionsUsedThisMonth),
        lastEntryDate: Value(updated.lastEntryDate),
        badges: Value(jsonEncode(updated.badges)),
      ),
    );

    return updated;
  }

  /// Uses a streak exemption (skip one day without breaking streak).
  /// Free users: 1/month. Premium: unlimited (checked at use case layer).
  /// Returns true if exemption was successfully applied.
  Future<bool> useExemption() async {
    final current = await getStreak();

    // Free user check: max 1 exemption per month
    if (current.exemptionsUsedThisMonth >= 1) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Only applicable if there's a gap of exactly 1 missed day
    if (current.lastEntryDate == null) return false;

    final lastDate = DateTime(
      current.lastEntryDate!.year,
      current.lastEntryDate!.month,
      current.lastEntryDate!.day,
    );
    final difference = today.difference(lastDate).inDays;

    if (difference != 2) return false; // Not applicable

    await (_db.update(_db.streakDataEntries))
        .write(
      StreakDataEntriesCompanion(
        exemptionsUsedThisMonth: Value(current.exemptionsUsedThisMonth + 1),
      ),
    );

    return true;
  }

  StreakData _rowToModel(dynamic row) {
    List<String> badges = [];
    try {
      final decoded = jsonDecode(row.badges);
      if (decoded is List) {
        badges = decoded.cast<String>();
      }
    } catch (_) {}

    return StreakData(
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      totalDays: row.totalDays,
      exemptionsUsedThisMonth: row.exemptionsUsedThisMonth,
      lastEntryDate: row.lastEntryDate,
      badges: badges,
    );
  }
}

@riverpod
StreakRepository streakRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return StreakRepository(db);
}
