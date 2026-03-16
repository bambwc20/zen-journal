import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_provider.g.dart';

@riverpod
Stream<CustomerInfo> customerInfo(Ref ref) {
  final controller = StreamController<CustomerInfo>.broadcast();
  final listener = (CustomerInfo info) => controller.add(info);
  Purchases.addCustomerInfoUpdateListener(listener);
  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(listener);
    controller.close();
  });
  return controller.stream;
}

@riverpod
Future<Offerings> offerings(Ref ref) async {
  return await Purchases.getOfferings();
}

class SubscriptionService {
  static Future<void> initialize({
    required String apiKey,
    String? userId,
  }) async {
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = userId,
    );
  }

  static Future<PurchaseResult> purchasePackage(Package package) async {
    return await Purchases.purchase(PurchaseParams.package(package));
  }

  static Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  static Future<bool> isPremium() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey('premium');
  }
}
