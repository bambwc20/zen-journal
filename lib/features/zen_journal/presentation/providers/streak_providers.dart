import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/manage_streak.dart';

part 'streak_providers.g.dart';

/// Gets the current streak data.
@riverpod
Future<StreakData> currentStreak(Ref ref) {
  final manageStreakUC = ref.watch(manageStreakProvider);
  return manageStreakUC.getStreak();
}

/// Checks if the user can use a streak exemption.
@riverpod
Future<bool> canUseExemption(Ref ref) {
  final manageStreakUC = ref.watch(manageStreakProvider);
  return manageStreakUC.canUseExemption();
}
