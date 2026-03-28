import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak_data.freezed.dart';
part 'streak_data.g.dart';

/// Domain model for streak tracking.
/// [badges] contains earned badge identifiers (e.g., "7_day", "30_day", "100_day", "365_day").
/// [exemptionsUsedThisMonth] tracks monthly streak exemption usage (free: 1/mo, premium: unlimited).
@freezed
abstract class StreakData with _$StreakData {
  const factory StreakData({
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    @Default(0) int totalDays,
    @Default(0) int exemptionsUsedThisMonth,
    DateTime? lastEntryDate,
    @Default([]) List<String> badges,
  }) = _StreakData;

  factory StreakData.fromJson(Map<String, dynamic> json) =>
      _$StreakDataFromJson(json);
}
