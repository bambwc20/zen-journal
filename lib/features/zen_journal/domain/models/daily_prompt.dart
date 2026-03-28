import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_prompt.freezed.dart';
part 'daily_prompt.g.dart';

/// Domain model for a daily writing prompt.
/// [category] is one of: self_reflection, gratitude, goals, relationships, creativity.
/// [isUsed] tracks whether the user has seen/used this prompt.
@freezed
abstract class DailyPrompt with _$DailyPrompt {
  const factory DailyPrompt({
    int? id,
    required String text,
    required String category,
    @Default(false) bool isUsed,
  }) = _DailyPrompt;

  factory DailyPrompt.fromJson(Map<String, dynamic> json) =>
      _$DailyPromptFromJson(json);
}
