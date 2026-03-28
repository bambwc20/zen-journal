import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

/// Domain model for a journal entry.
/// [content] stores the rich text as Delta JSON string.
/// [plainText] stores the plain text version for search indexing.
/// [moodLevel] is 1-5 scale (1=very bad, 5=very good).
/// [photos] stores file paths of attached images.
@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    int? id,
    required String content,
    @Default('') String plainText,
    @Default(3) int moodLevel,
    @Default([]) List<String> photos,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int wordCount,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
