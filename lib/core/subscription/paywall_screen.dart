import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      body: SafeArea(
        child: offeringsAsync.when(
          data: (offerings) => _buildPaywall(context, ref, offerings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
        ),
      ),
    );
  }

  Widget _buildPaywall(
    BuildContext context,
    WidgetRef ref,
    Offerings offerings,
  ) {
    final current = offerings.current;
    if (current == null) {
      return const Center(child: Text('구독 상품이 없습니다'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.star, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            '프리미엄으로 업그레이드',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '모든 기능을 제한 없이 사용하세요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 32),
          ...current.availablePackages.map(
            (pkg) => _PackageCard(package: pkg),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              await SubscriptionService.restorePurchases();
            },
            child: const Text('구매 복원'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final Package package;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(package.storeProduct.title),
        subtitle: Text(package.storeProduct.description),
        trailing: FilledButton(
          onPressed: () async {
            try {
              await SubscriptionService.purchasePackage(package);
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (e) {
              // Purchase cancelled or failed
            }
          },
          child: Text(package.storeProduct.priceString),
        ),
      ),
    );
  }
}
