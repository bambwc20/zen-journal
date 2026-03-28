import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_boilerplate/core/push/push_service.dart';

part 'notification_service.g.dart';

/// App-specific notification logic for ZenJournal.
///
/// Uses [PushService] from core/push/ for low-level notification delivery.
/// This service handles:
/// - CRM onboarding sequence scheduling (D0–D30)
/// - Daily journal reminder (repeating)
/// - Dormant user re-engagement reminders
///
/// Server-side FCM is NOT used in MVP.
// TODO: v1.1 서버사이드 FCM으로 세그먼트 기반 푸시 전환
class NotificationService {
  final PushService _pushService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Notification ID ranges to avoid collisions:
  /// - 1000–1099: CRM onboarding sequence
  /// - 2000: Daily journal reminder
  /// - 3000–3099: Dormant re-engagement
  static const int _crmBaseId = 1000;
  static const int _reminderId = 2000;
  static const int _dormantBaseId = 3000;

  /// Android notification channel for CRM messages.
  static const String _crmChannelId = 'crm_channel';
  static const String _crmChannelName = 'Motivational Messages';
  static const String _crmChannelDesc =
      'Onboarding tips, streak reminders, and journaling motivation';

  /// Android notification channel for journal reminders.
  static const String _reminderChannelId = 'reminder_channel';
  static const String _reminderChannelName = 'Journal Reminder';
  static const String _reminderChannelDesc =
      'Daily reminder to write your journal entry';

  NotificationService(this._pushService);

  /// Schedules a CRM notification at [dayOffset] days from now.
  ///
  /// Used by [ScheduleNotifications] use case to queue the D0–D30
  /// onboarding sequence as local notifications.
  Future<void> scheduleCrmNotification({
    required int dayOffset,
    required String title,
    required String body,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      Duration(days: dayOffset),
    );

    final androidDetails = AndroidNotificationDetails(
      _crmChannelId,
      _crmChannelName,
      channelDescription: _crmChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      _crmBaseId + dayOffset,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Schedules a daily repeating journal reminder at [time].
  ///
  /// Cancels any existing reminder before scheduling to avoid duplicates.
  Future<void> scheduleJournalReminder(TimeOfDay time) async {
    // Cancel existing reminder first
    await _localNotifications.cancel(_reminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      _reminderId,
      'Time to journal',
      'Take a moment to capture your day. Even a few words make a difference.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
  }

  /// Schedules a dormant re-engagement notification after [inactiveDays].
  ///
  /// Called when the app detects the user hasn't written in a while.
  /// Schedules a gentle reminder at the specified inactive day threshold.
  Future<void> scheduleDormantReminder(int inactiveDays) async {
    final title = inactiveDays >= 30
        ? 'Your journal is safe'
        : 'We miss your journaling';

    final body = inactiveDays >= 30
        ? 'Your entries are encrypted and secure. Come back anytime to continue your journey.'
        : 'Taking a break is okay. When you\'re ready, your journal is here waiting.';

    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      Duration(days: inactiveDays),
    );

    final androidDetails = AndroidNotificationDetails(
      _crmChannelId,
      _crmChannelName,
      channelDescription: _crmChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      _dormantBaseId + inactiveDays,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Cancels all CRM onboarding notifications (D0–D30).
  Future<void> cancelAllCrmNotifications() async {
    for (var i = 0; i <= 30; i++) {
      await _localNotifications.cancel(_crmBaseId + i);
    }
  }

  /// Cancels the daily journal reminder.
  Future<void> cancelJournalReminder() async {
    await _localNotifications.cancel(_reminderId);
  }

  /// Cancels all dormant re-engagement notifications.
  Future<void> cancelAllDormantNotifications() async {
    for (final days in [7, 10, 30, 45]) {
      await _localNotifications.cancel(_dormantBaseId + days);
    }
  }

  /// Cancels all ZenJournal-managed notifications.
  Future<void> cancelAll() async {
    await cancelAllCrmNotifications();
    await cancelJournalReminder();
    await cancelAllDormantNotifications();
  }
}

@riverpod
NotificationService notificationService(Ref ref) {
  final pushService = ref.watch(pushServiceProvider);
  return NotificationService(pushService);
}
