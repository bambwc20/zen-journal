import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_stats.freezed.dart';
part 'mood_stats.g.dart';

/// Aggregated mood statistics for a date range.
/// [averageMood] is the mean mood level.
/// [moodDistribution] maps mood level (1-5) to count.
/// [tagFrequency] maps tag name to occurrence count.
@freezed
abstract class MoodStats with _$MoodStats {
  const factory MoodStats({
    @Default(0.0) double averageMood,
    @Default({}) Map<int, int> moodDistribution,
    @Default({}) Map<String, int> tagFrequency,
    @Default(0) int totalEntries,
  }) = _MoodStats;

  factory MoodStats.fromJson(Map<String, dynamic> json) =>
      _$MoodStatsFromJson(json);
}
