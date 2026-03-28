import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/models/ai_reflection.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/weekly_report.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/get_ai_reflection.dart';

part 'ai_reflection_providers.g.dart';

/// Gets the AI reflection for a specific journal entry.
/// Returns null if no reflection exists yet.
@riverpod
Future<AiReflection?> reflectionForEntry(Ref ref, int entryId) async {
  final useCase = ref.watch(getAiReflectionProvider);
  try {
    return await useCase.execute(entryId);
  } on AiReflectionLimitReachedException {
    // Return null and let the UI handle the limit reached state
    return null;
  }
}

/// Gets the remaining free AI reflections for this week.
@riverpod
Future<int> remainingFreeReflections(Ref ref) {
  final useCase = ref.watch(getAiReflectionProvider);
  return useCase.getRemainingFree();
}

/// Gets a weekly AI report for premium users.
@riverpod
Future<WeeklyReport?> weeklyReport(Ref ref, DateTime weekStart) {
  final useCase = ref.watch(getAiReflectionProvider);
  return useCase.getWeeklyReport(weekStart);
}

/// Manages the AI reflection generation state (loading, error, etc.).
@riverpod
class AiReflectionState extends _$AiReflectionState {
  @override
  AsyncValue<AiReflection?> build() => const AsyncValue.data(null);

  /// Requests a new AI reflection for the given entry.
  Future<void> generateReflection(int entryId) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(getAiReflectionProvider);
      final reflection = await useCase.execute(entryId);
      state = AsyncValue.data(reflection);
    } on AiReflectionLimitReachedException catch (e, st) {
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
