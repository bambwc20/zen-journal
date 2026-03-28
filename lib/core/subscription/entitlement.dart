import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_provider.dart';

class EntitlementGate extends ConsumerWidget {
  const EntitlementGate({
    super.key,
    required this.child,
    this.placeholder,
    this.entitlementId = 'premium',
  });

  final Widget child;
  final Widget? placeholder;
  final String entitlementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerInfoAsync = ref.watch(customerInfoProvider);

    return customerInfoAsync.when(
      data: (info) {
        final isEntitled =
            info.entitlements.active.containsKey(entitlementId);
        if (isEntitled) return child;
        return placeholder ?? const _LockedFeature();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => placeholder ?? const _LockedFeature(),
    );
  }
}

class _LockedFeature extends StatelessWidget {
  const _LockedFeature();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline),
          SizedBox(width: 8),
          Text('Premium Feature'),
        ],
      ),
    );
  }
}
