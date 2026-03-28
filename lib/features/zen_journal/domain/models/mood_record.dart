import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_record.freezed.dart';
part 'mood_record.g.dart';

/// Domain model for a mood record.
/// [level] is 1-5 (1=very bad, 5=very good).
/// [tags] are mood-related tags (e.g., "stressed", "grateful").
/// [entryId] links to the associated journal entry (nullable).
@freezed
abstract class MoodRecord with _$MoodRecord {
  const factory MoodRecord({
    int? id,
    required int level,
    @Default([]) List<String> tags,
    required DateTime date,
    int? entryId,
  }) = _MoodRecord;

  factory MoodRecord.fromJson(Map<String, dynamic> json) =>
      _$MoodRecordFromJson(json);
}
