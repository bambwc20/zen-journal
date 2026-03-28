import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_reflection.freezed.dart';
part 'ai_reflection.g.dart';

/// Domain model for an AI-generated reflection on a journal entry.
/// Contains three reflection types:
/// - [emotionAnalysis]: analysis of the emotional content
/// - [patternInsight]: patterns detected across recent entries
/// - [actionSuggestion]: suggested actions for the user
@freezed
abstract class AiReflection with _$AiReflection {
  const factory AiReflection({
    int? id,
    required int entryId,
    required String emotionAnalysis,
    required String patternInsight,
    required String actionSuggestion,
    required DateTime createdAt,
  }) = _AiReflection;

  factory AiReflection.fromJson(Map<String, dynamic> json) =>
      _$AiReflectionFromJson(json);
}
