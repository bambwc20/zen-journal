import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/streak_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';

part 'manage_streak.g.dart';

/// Use case for managing streak updates and badge checks.
///
/// Handles:
/// - Streak updates on journal entry save
/// - Badge milestone detection (7, 30, 100, 365 days)
/// - Exemption usage (free: 1/month, premium: unlimited)
/// - Monthly exemption reset
class ManageStreak {
  final StreakRepository _repo;
  final bool _isPremium;

  /// Badge milestones and their display names.
  static const Map<String, String> badgeDisplayNames = {
    '7_day': '7 Day Streak',
    '30_day': '30 Day Streak',
    '100_day': '100 Day Streak',
    '365_day': '365 Day Streak',
  };

  ManageStreak(this._repo, {required bool isPremium})
      : _isPremium = isPremium;

  /// Gets the current streak data.
  Future<StreakData> getStreak() async {
    return await _repo.getStreak();
  }

  /// Updates the streak (called after a journal entry is saved).
  /// Returns the updated streak and a list of newly earned badges.
  Future<({StreakData streak, List<String> newBadges})> updateStreak() async {
    final before = await _repo.getStreak();
    final after = await _repo.updateStreak();

    // Detect newly earned badges
    final newBadges = after.badges
        .where((badge) => !before.badges.contains(badge))
        .toList();

    return (streak: after, newBadges: newBadges);
  }

  /// Uses a streak exemption (skip one day without breaking streak).
  /// Free users: 1 per month. Premium users: unlimited.
  /// Returns true if the exemption was successfully applied.
  Future<bool> useExemption() async {
    if (_isPremium) {
      // Premium users get unlimited exemptions
      return await _repo.useExemption();
    }
    // Free users: repository already enforces 1/month limit
    return await _repo.useExemption();
  }

  /// Checks if the user is eligible to use an exemption.
  Future<bool> canUseExemption() async {
    final streak = await _repo.getStreak();
    if (_isPremium) return true;
    return streak.exemptionsUsedThisMonth < 1;
  }

  /// Gets a display-friendly badge name.
  static String getBadgeDisplayName(String badgeId) {
    return badgeDisplayNames[badgeId] ?? badgeId;
  }

  // TODO: v1.1 — Premium badges (custom designs, animations)
  // TODO: v1.1 — Streak recovery purchase option
}

@riverpod
ManageStreak manageStreak(Ref ref) {
  final repo = ref.watch(streakRepositoryProvider);
  final isPremium = ref.watch(isPremiumProvider);
  return ManageStreak(repo, isPremium: isPremium);
}
