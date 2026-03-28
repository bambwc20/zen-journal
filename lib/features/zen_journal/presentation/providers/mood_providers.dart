import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/data/repositories/mood_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_record.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_stats.dart';

part 'mood_providers.g.dart';

/// Gets today's mood record, if any.
@riverpod
Future<MoodRecord?> todayMood(Ref ref) {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.getMoodByDate(DateTime.now());
}

/// Gets mood records for a date range.
@riverpod
Future<List<MoodRecord>> moodsByDateRange(
  Ref ref,
  DateTime start,
  DateTime end,
) {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.getMoodsByDateRange(start, end);
}

/// Watches mood records for a date range as a stream.
@riverpod
Stream<List<MoodRecord>> moodsByDateRangeStream(
  Ref ref,
  DateTime start,
  DateTime end,
) {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.watchMoodsByDateRange(start, end);
}

/// Gets mood statistics for the current week (last 7 days).
@riverpod
Future<MoodStats> weeklyMoodStats(Ref ref) {
  final repo = ref.watch(moodRepositoryProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final end = start.add(const Duration(days: 7));
  return repo.getMoodStats(start, end);
}

/// Gets mood statistics for the current month.
@riverpod
Future<MoodStats> monthlyMoodStats(Ref ref) {
  final repo = ref.watch(moodRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1);
  return repo.getMoodStats(start, end);
}

/// Maps a date to its mood level for calendar heatmap display.
@riverpod
Future<Map<DateTime, int>> moodHeatmapData(
  Ref ref,
  DateTime monthStart,
) async {
  final repo = ref.watch(moodRepositoryProvider);
  final start = DateTime(monthStart.year, monthStart.month, 1);
  final end = DateTime(monthStart.year, monthStart.month + 1, 1);
  final moods = await repo.getMoodsByDateRange(start, end);

  final heatmap = <DateTime, int>{};
  for (final mood in moods) {
    final dateKey = DateTime(mood.date.year, mood.date.month, mood.date.day);
    heatmap[dateKey] = mood.level;
  }
  return heatmap;
}

/// Manages the selected mood level during journal editing.
@riverpod
class SelectedMoodLevel extends _$SelectedMoodLevel {
  @override
  int build() => 3; // Default: neutral

  void setLevel(int level) {
    if (level >= 1 && level <= 5) {
      state = level;
    }
  }
}
