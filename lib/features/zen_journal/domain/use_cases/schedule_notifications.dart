import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_boilerplate/features/zen_journal/data/data_sources/notification_service.dart';

part 'schedule_notifications.g.dart';

/// Use case for managing all ZenJournal notification scheduling.
///
/// Called at app startup to ensure CRM onboarding sequence is scheduled
/// and dormant reminders are appropriately set.
///
/// Handles:
/// - First-launch CRM sequence (D0–D30) — one-time setup
/// - Journal reminder time updates
/// - Dormant user detection and reminder scheduling
class ScheduleNotifications {
  final NotificationService _notificationService;

  /// SharedPreferences key for tracking whether CRM sequence was initialized.
  static const String _crmInitializedKey = 'crm_sequence_initialized';

  /// SharedPreferences key for the user's preferred reminder hour.
  static const String _reminderHourKey = 'journal_reminder_hour';

  /// SharedPreferences key for the user's preferred reminder minute.
  static const String _reminderMinuteKey = 'journal_reminder_minute';

  /// CRM onboarding sequence messages.
  /// Matches the sequence defined in docs/CRM_SEQUENCES.md.
  static const List<({int day, String title, String body})> _crmSequence = [
    (
      day: 0,
      title: 'Welcome to ZenJournal!',
      body:
          'Start your first journal entry today. Just 2 minutes to capture your day.',
    ),
    (
      day: 1,
      title: 'Your AI insight is ready',
      body:
          'Yesterday\'s entry got an AI reflection. Tap to see what patterns it found.',
    ),
    (
      day: 3,
      title: '3-day streak! Keep going',
      body:
          'You\'ve journaled 3 days in a row. This momentum builds lasting habits.',
    ),
    (
      day: 5,
      title: 'Pro trial ends in 2 days',
      body:
          'Set up encrypted backup before your trial ends. Your data deserves protection.',
    ),
    (
      day: 7,
      title: '7-day streak achieved!',
      body:
          'Congratulations! Unlock your Weekly AI Report with Pro to see the full picture.',
    ),
    (
      day: 14,
      title: '2 weeks of emotions analyzed',
      body:
          'Your 2-week mood patterns are in. Check your AI insights to understand your trends.',
    ),
    (
      day: 21,
      title: 'Your journaling style is unique',
      body:
          'AI has learned your patterns over 3 weeks. Personalized prompts are getting smarter.',
    ),
    (
      day: 30,
      title: 'One month of journaling!',
      body:
          'Export your month\'s journey as a PDF keepsake. Available with Pro.',
    ),
  ];

  ScheduleNotifications(this._notificationService);

  /// Initializes all notifications on first launch.
  ///
  /// Should be called once during app startup (e.g., from main or splash).
  /// Idempotent: CRM sequence is only scheduled once (tracked via SharedPreferences).
  Future<void> initializeNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyInitialized = prefs.getBool(_crmInitializedKey) ?? false;

    if (!alreadyInitialized) {
      // Schedule the D0–D30 CRM onboarding sequence
      for (final message in _crmSequence) {
        await _notificationService.scheduleCrmNotification(
          dayOffset: message.day,
          title: message.title,
          body: message.body,
        );
      }
      await prefs.setBool(_crmInitializedKey, true);
    }

    // Restore saved reminder time if one was set
    final savedHour = prefs.getInt(_reminderHourKey);
    final savedMinute = prefs.getInt(_reminderMinuteKey);
    if (savedHour != null && savedMinute != null) {
      await _notificationService.scheduleJournalReminder(
        TimeOfDay(hour: savedHour, minute: savedMinute),
      );
    }
  }

  /// Updates the daily journal reminder time.
  ///
  /// Persists the time to SharedPreferences so it survives app restarts.
  /// Cancels existing reminder and schedules a new one.
  Future<void> updateReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);
    await _notificationService.scheduleJournalReminder(time);
  }

  /// Checks the last entry date and schedules dormant reminders if needed.
  ///
  /// Call this on app startup with the most recent journal entry date.
  /// If [lastEntryDate] is null, the user has never written — skip dormant logic.
  Future<void> checkAndScheduleDormantReminder(
    DateTime? lastEntryDate,
  ) async {
    if (lastEntryDate == null) return;

    final daysSinceLastEntry =
        DateTime.now().difference(lastEntryDate).inDays;

    // Cancel any previously scheduled dormant notifications
    await _notificationService.cancelAllDormantNotifications();

    if (daysSinceLastEntry >= 30) {
      // Already 30+ days dormant — schedule the 30-day message immediately
      // and the 45-day follow-up
      await _notificationService.scheduleDormantReminder(0); // now
      final daysUntil45 = 45 - daysSinceLastEntry;
      if (daysUntil45 > 0) {
        await _notificationService.scheduleDormantReminder(daysUntil45);
      }
    } else if (daysSinceLastEntry >= 7) {
      // Already 7+ days dormant — schedule the 7-day message immediately
      // and the remaining follow-ups
      await _notificationService.scheduleDormantReminder(0); // now
      final daysUntil30 = 30 - daysSinceLastEntry;
      if (daysUntil30 > 0) {
        await _notificationService.scheduleDormantReminder(daysUntil30);
      }
    } else {
      // Active recently — schedule future dormant reminders
      final daysUntil7 = 7 - daysSinceLastEntry;
      final daysUntil10 = 10 - daysSinceLastEntry;
      final daysUntil30 = 30 - daysSinceLastEntry;

      if (daysUntil7 > 0) {
        await _notificationService.scheduleDormantReminder(daysUntil7);
      }
      if (daysUntil10 > 0) {
        await _notificationService.scheduleDormantReminder(daysUntil10);
      }
      if (daysUntil30 > 0) {
        await _notificationService.scheduleDormantReminder(daysUntil30);
      }
    }
  }
}

@riverpod
ScheduleNotifications scheduleNotifications(Ref ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ScheduleNotifications(notificationService);
}
