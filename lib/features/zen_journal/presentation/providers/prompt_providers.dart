import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/data/repositories/prompt_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/daily_prompt.dart';

part 'prompt_providers.g.dart';

/// Gets today's daily writing prompt.
/// Seeds prompts on first access if the table is empty.
@riverpod
Future<DailyPrompt> todayPrompt(Ref ref) async {
  final repo = ref.watch(promptRepositoryProvider);
  await repo.seedPromptsIfEmpty();
  return repo.getTodayPrompt();
}

/// Manages the state of whether the current prompt was used.
@riverpod
class PromptUsedState extends _$PromptUsedState {
  @override
  bool build() => false;

  void markUsed() {
    state = true;
  }

  void reset() {
    state = false;
  }
}

/// Skips the current prompt and gets the next one.
@riverpod
Future<DailyPrompt> nextPrompt(Ref ref) {
  final repo = ref.watch(promptRepositoryProvider);
  return repo.getNextPrompt();
}
