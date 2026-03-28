import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:flutter_boilerplate/core/subscription/subscription_provider.dart';

/// ZenJournal custom paywall screen.
///
/// Displays as a bottom-sheet modal with:
/// - 7-day free trial emphasis
/// - Monthly / Yearly / Lifetime pricing from RevenueCat offerings
/// - Free vs Pro feature comparison
/// - "Later" and "Restore purchases" buttons
///
/// Prices are loaded dynamically from RevenueCat [offeringsProvider].
/// This does NOT modify core/subscription/ files.
class ZenJournalPaywallScreen extends ConsumerWidget {
  const ZenJournalPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: offeringsAsync.when(
        data: (offerings) => _buildPaywallContent(context, ref, offerings),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(64),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => _buildFallbackPaywall(context),
      ),
    );
  }

  Widget _buildPaywallContent(
    BuildContext context,
    WidgetRef ref,
    Offerings offerings,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = offerings.current;

    // Find packages by identifier
    Package? monthlyPackage;
    Package? yearlyPackage;
    Package? lifetimePackage;

    if (current != null) {
      for (final pkg in current.availablePackages) {
        final identifier = pkg.storeProduct.identifier;
        if (identifier.contains('monthly')) {
          monthlyPackage = pkg;
        } else if (identifier.contains('yearly') ||
            identifier.contains('annual')) {
          yearlyPackage = pkg;
        } else if (identifier.contains('lifetime')) {
          lifetimePackage = pkg;
        }
      }

      // Fallback: try by package type
      monthlyPackage ??= current.monthly;
      yearlyPackage ??= current.annual;
      lifetimePackage ??= current.lifetime;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9B7B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: Color(0xFF6B9B7B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ZenJournal Pro',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start your 7-day free trial',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF6B9B7B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Unlock all features. Cancel anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Feature comparison
            _buildFeatureComparison(context),

            const SizedBox(height: 24),

            // Pricing cards
            if (yearlyPackage != null)
              _PricingCard(
                package: yearlyPackage,
                label: 'Yearly',
                subtitle: _buildYearlySubtitle(yearlyPackage),
                badge: '40% OFF',
                isRecommended: true,
                onPurchased: () => _onPurchaseSuccess(context),
              ),
            if (monthlyPackage != null)
              _PricingCard(
                package: monthlyPackage,
                label: 'Monthly',
                subtitle: null,
                isRecommended: false,
                onPurchased: () => _onPurchaseSuccess(context),
              ),
            if (lifetimePackage != null)
              _PricingCard(
                package: lifetimePackage,
                label: 'Lifetime',
                subtitle: 'One-time purchase, forever access',
                isRecommended: false,
                onPurchased: () => _onPurchaseSuccess(context),
              ),

            const SizedBox(height: 16),

            // 7-day trial reminder
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B9B7B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF6B9B7B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your free trial starts today. You won\'t be charged for 7 days. Cancel anytime in Settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Restore purchases
            Center(
              child: TextButton(
                onPressed: () async {
                  try {
                    await SubscriptionService.restorePurchases();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchases restored')),
                      );
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restore failed: $e')),
                      );
                    }
                  }
                },
                child: Text(
                  'Restore purchases',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            // Later button
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the yearly subtitle showing per-month price from RevenueCat data.
  String _buildYearlySubtitle(Package yearlyPackage) {
    final price = yearlyPackage.storeProduct.price;
    final monthlyEquivalent = (price / 12).toStringAsFixed(2);
    final currencyCode = yearlyPackage.storeProduct.currencyCode;
    return '${yearlyPackage.storeProduct.priceString}/yr ($currencyCode $monthlyEquivalent/mo)';
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Free vs Pro',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            feature: 'Journal entries',
            free: '1/day, 500 chars',
            pro: 'Unlimited',
          ),
          _FeatureRow(
            feature: 'AI Reflections',
            free: '2/week',
            pro: 'Unlimited + Deep analysis',
          ),
          _FeatureRow(
            feature: 'Weekly AI Report',
            free: '-',
            pro: 'Included',
          ),
          _FeatureRow(
            feature: 'Search',
            free: 'Last 30 days',
            pro: 'All time + AI semantic',
          ),
          _FeatureRow(
            feature: 'Export',
            free: '-',
            pro: 'PDF/TXT/JSON/CSV',
          ),
          _FeatureRow(
            feature: 'Cloud backup',
            free: 'Manual only',
            pro: 'Auto + E2E encrypted',
          ),
          _FeatureRow(
            feature: 'Themes',
            free: 'Default',
            pro: '10 premium + Dark mode',
          ),
          _FeatureRow(
            feature: 'Ads',
            free: 'Banner ads',
            pro: 'Ad-free',
          ),
        ],
      ),
    );
  }

  /// Fallback paywall when RevenueCat is not configured or fails to load.
  /// Shows static feature comparison and a close button.
  Widget _buildFallbackPaywall(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9B7B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: Color(0xFF6B9B7B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ZenJournal Pro',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock all features',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF6B9B7B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Feature comparison
            _buildFeatureComparison(context),

            const SizedBox(height: 24),

            // Static pricing display
            _StaticPricingTile(
              label: 'Yearly',
              price: '\$29.99/yr',
              subtitle: '\$2.49/mo',
              badge: '40% OFF',
              isRecommended: true,
            ),
            _StaticPricingTile(
              label: 'Monthly',
              price: '\$4.99/mo',
            ),
            _StaticPricingTile(
              label: 'Lifetime',
              price: '\$79.99',
              subtitle: 'One-time purchase',
            ),

            const SizedBox(height: 16),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In-app purchases will be available soon. '
                      'Enjoy the free features for now!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Continue with Free',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPurchaseSuccess(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

/// A single pricing option card.
class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.package,
    required this.label,
    this.subtitle,
    this.badge,
    required this.isRecommended,
    required this.onPurchased,
  });

  final Package package;
  final String label;
  final String? subtitle;
  final String? badge;
  final bool isRecommended;
  final VoidCallback onPurchased;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryGreen = Color(0xFF6B9B7B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isRecommended
            ? primaryGreen.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isRecommended
              ? const BorderSide(color: primaryGreen, width: 2)
              : BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            try {
              await SubscriptionService.purchasePackage(package);
              onPurchased();
            } catch (e) {
              // Purchase cancelled or failed — do nothing
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isRecommended ? primaryGreen : colorScheme.primary,
                  ),
                  onPressed: () async {
                    try {
                      await SubscriptionService.purchasePackage(package);
                      onPurchased();
                    } catch (e) {
                      // Purchase cancelled or failed
                    }
                  },
                  child: Text(package.storeProduct.priceString),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row in the free-vs-pro feature comparison table.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.free,
    required this.pro,
  });

  final String feature;
  final String free;
  final String pro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B9B7B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Static pricing tile used when RevenueCat is not configured.
class _StaticPricingTile extends StatelessWidget {
  const _StaticPricingTile({
    required this.label,
    required this.price,
    this.subtitle,
    this.badge,
    this.isRecommended = false,
  });

  final String label;
  final String price;
  final String? subtitle;
  final String? badge;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryGreen = Color(0xFF6B9B7B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isRecommended
              ? primaryGreen.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended
                ? primaryGreen
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isRecommended ? primaryGreen : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
