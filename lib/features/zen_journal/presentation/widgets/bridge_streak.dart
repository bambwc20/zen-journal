import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/paywall_screen.dart';

/// Bridge point widget shown when the user achieves a 7-day streak.
///
/// Congratulates the user and promotes the Pro weekly AI report feature,
/// then opens the paywall on tap.
class BridgeStreak extends ConsumerWidget {
  const BridgeStreak({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accentOrange = Color(0xFFF5A623);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentOrange.withValues(alpha: 0.12),
            accentOrange.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: accentOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '7-day streak achieved!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Congratulations on 7 days of journaling!\n'
            'With Pro, you can review this week with an AI weekly report '
            'that summarizes your mood trends and key insights.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showPaywall(context),
              icon: const Icon(Icons.insights, size: 18),
              label: const Text('Unlock weekly AI reports'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: ZenJournalPaywallScreen(),
      ),
    );
  }
}
