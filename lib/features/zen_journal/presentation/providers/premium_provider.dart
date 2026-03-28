import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/subscription/subscription_provider.dart';

part 'premium_provider.g.dart';

/// Derives the premium status from the customerInfo stream.
/// Returns true if the user has an active 'premium' entitlement.
@riverpod
bool isPremium(Ref ref) {
  final subscription = ref.watch(customerInfoProvider);
  return subscription.when(
    data: (info) => info.entitlements.active.containsKey('premium'),
    loading: () => false,
    error: (_, __) => false,
  );
}
