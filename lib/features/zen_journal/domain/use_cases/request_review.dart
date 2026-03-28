import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_boilerplate/core/analytics/analytics_service.dart';

part 'request_review.g.dart';

/// Use case for requesting an in-app review at the right moment.
///
/// Triggers:
/// - 7-day streak achieved
/// - User taps "Helpful" on an AI reflection
///
/// Guards:
/// - Only requests once per 90 days (to avoid user annoyance)
/// - Uses InAppReview.isAvailable() check before requesting
/// - No negative intercept UI — delegates entirely to the native review dialog
///
/// Note: The native review dialog is controlled by the OS. On iOS, the system
/// may choose not to show the dialog even when requested (Apple limits to
/// 3 times per 365 days). On Android, the In-App Review API has similar
/// rate-limiting. This is expected behavior.
class RequestReview {
  final InAppReview _inAppReview;
  final AnalyticsService _analytics;

  /// SharedPreferences key for the last review request timestamp.
  static const String _lastReviewRequestKey = 'last_review_request_timestamp';

  /// Minimum days between review requests.
  static const int _cooldownDays = 90;

  RequestReview(this._inAppReview, this._analytics);

  /// Requests a review after a 7-day streak achievement.
  ///
  /// Returns true if the review dialog was requested, false if skipped.
  Future<bool> requestOnStreakAchievement(int streakDays) async {
    if (streakDays < 7) return false;
    // Only trigger on exactly 7-day milestones (7, 14, 21, ...)
    if (streakDays % 7 != 0) return false;

    return await _requestReview(trigger: 'streak_$streakDays');
  }

  /// Requests a review after the user taps "Helpful" on an AI reflection.
  ///
  /// Returns true if the review dialog was requested, false if skipped.
  Future<bool> requestOnReflectionHelpful() async {
    return await _requestReview(trigger: 'reflection_helpful');
  }

  /// Core review request logic with cooldown and availability checks.
  Future<bool> _requestReview({required String trigger}) async {
    // Check cooldown period
    final prefs = await SharedPreferences.getInstance();
    final lastRequestMs = prefs.getInt(_lastReviewRequestKey);

    if (lastRequestMs != null) {
      final lastRequest =
          DateTime.fromMillisecondsSinceEpoch(lastRequestMs);
      final daysSinceLastRequest =
          DateTime.now().difference(lastRequest).inDays;

      if (daysSinceLastRequest < _cooldownDays) {
        return false;
      }
    }

    // Check if the native review dialog is available
    final isAvailable = await _inAppReview.isAvailable();
    if (!isAvailable) {
      return false;
    }

    // Request the review
    await _inAppReview.requestReview();

    // Record the request timestamp
    await prefs.setInt(
      _lastReviewRequestKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    // Log analytics event
    await _analytics.logEvent(
      name: 'review_requested',
      parameters: {'trigger': trigger},
    );

    return true;
  }
}

@riverpod
RequestReview requestReview(Ref ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return RequestReview(InAppReview.instance, analytics);
}
