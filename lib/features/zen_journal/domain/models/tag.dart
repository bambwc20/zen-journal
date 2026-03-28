import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// Domain model for a tag.
/// [isCustom] differentiates user-created tags from the 20 predefined ones.
/// [usageCount] tracks how many entries use this tag.
@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    int? id,
    required String name,
    @Default(false) bool isCustom,
    @Default(0) int usageCount,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
