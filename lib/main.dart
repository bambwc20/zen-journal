import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app.dart';
import 'core/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화 (반드시 첫 번째)
  await Firebase.initializeApp();

  // 2. RevenueCat 초기화 (Firebase 이후)
  await Purchases.configure(
    PurchasesConfiguration(
      const String.fromEnvironment('REVENUECAT_API_KEY'),
    ),
  );

  // 3. AdMob 초기화 (마지막)
  await MobileAds.instance.initialize();

  // 4. 푸시 알림 초기화
  final pushService = PushService();
  await pushService.initialize();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
