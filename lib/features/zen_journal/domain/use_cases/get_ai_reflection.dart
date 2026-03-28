import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/ai_reflection_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/ai_reflection.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/weekly_report.dart';

part 'get_ai_reflection.g.dart';

/// Exception thrown when the user has reached their free AI reflection limit.
class AiReflectionLimitReachedException implements Exception {
  final int usedCount;
  final int maxFree;

  const AiReflectionLimitReachedException({
    required this.usedCount,
    required this.maxFree,
  });

  @override
  String toString() =>
      'AI reflection limit reached: $usedCount/$maxFree used this week. '
      'Upgrade to Pro for unlimited AI reflections.';
}

/// Use case for requesting AI reflections with free-tier limit enforcement.
///
/// Free users: 2 AI reflections per week.
/// Premium users: unlimited reflections + weekly reports.
class GetAiReflection {
  final AiReflectionRepository _repo;
  final bool _isPremium;

  GetAiReflection(this._repo, {required bool isPremium})
      : _isPremium = isPremium;

  /// Generates an AI reflection for a journal entry.
  ///
  /// For free users, checks the weekly usage limit (2/week) before calling the API.
  /// For premium users, always allows generation.
  ///
  /// Returns the cached reflection if one already exists for the entry.
  /// Throws [AiReflectionLimitReachedException] if the free limit is reached.
  Future<AiReflection> execute(int entryId) async {
    // Check for existing reflection first
    final existing = await _repo.getReflectionForEntry(entryId);
    if (existing != null) return existing;

    // Check free user limit
    if (!_isPremium) {
      final remaining = await _repo.getRemainingFreeReflections();
      if (remaining <= 0) {
        final used = 2; // maxFree is always 2
        throw AiReflectionLimitReachedException(usedCount: used, maxFree: 2);
      }
    }

    return await _repo.generateReflection(entryId);
  }

  /// Gets the remaining free reflections count for the current week.
  Future<int> getRemainingFree() async {
    if (_isPremium) return -1; // Unlimited
    return await _repo.getRemainingFreeReflections();
  }

  /// Gets a weekly AI report (premium only).
  /// Returns null if user is not premium or not enough data.
  Future<WeeklyReport?> getWeeklyReport(DateTime weekStart) async {
    if (!_isPremium) return null;
    return await _repo.getWeeklyReport(weekStart);
  }

  // TODO: v1.1 — Rewarded ad for extra free reflection
  // Future<bool> watchAdForExtraReflection() async { ... }
}

@riverpod
GetAiReflection getAiReflection(Ref ref) {
  final repo = ref.watch(aiReflectionRepositoryProvider);
  final isPremium = ref.watch(isPremiumProvider);
  return GetAiReflection(repo, isPremium: isPremium);
}
