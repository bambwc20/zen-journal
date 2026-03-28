import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app.dart';
import 'core/subscription/subscription_provider.dart';
import 'core/push/push_service.dart';
import 'features/zen_journal/data/data_sources/notification_service.dart';
import 'features/zen_journal/domain/use_cases/schedule_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Catch async errors not handled by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };

  // 1. Firebase 초기화 (반드시 첫 번째)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed (expected if google-services.json missing): $e');
  }

  // 2. RevenueCat 초기화 (Firebase 이후)
  const rcApiKey = String.fromEnvironment('REVENUECAT_API_KEY');
  if (rcApiKey.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(rcApiKey));
    revenueCatConfigured = true;
  } else {
    debugPrint('RevenueCat API key not set. Skipping configuration.');
  }

  // 3. AdMob 초기화
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob initialization failed: $e');
  }

  // 4. 푸시 알림 초기화
  try {
    final pushService = PushService();
    await pushService.initialize();

    // 5. ZenJournal CRM 알림 시퀀스 초기화
    final notificationService = NotificationService(pushService);
    final scheduleNotifications = ScheduleNotifications(notificationService);
    await scheduleNotifications.initializeNotifications();
  } catch (e) {
    debugPrint('Push/notification initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
