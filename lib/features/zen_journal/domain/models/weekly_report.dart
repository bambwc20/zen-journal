import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_report.freezed.dart';
part 'weekly_report.g.dart';

/// Domain model for a weekly AI-generated report (premium feature).
/// Summarizes a week of journal entries with mood trends and key insights.
@freezed
abstract class WeeklyReport with _$WeeklyReport {
  const factory WeeklyReport({
    required DateTime weekStart,
    required String summary,
    required String moodTrend,
    @Default([]) List<String> keyInsights,
    @Default(0) int totalEntries,
  }) = _WeeklyReport;

  factory WeeklyReport.fromJson(Map<String, dynamic> json) =>
      _$WeeklyReportFromJson(json);
}
