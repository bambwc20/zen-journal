import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/paywall_screen.dart';

/// Bridge point widget shown when the user has exhausted their
/// free AI reflections (2/week for free users).
///
/// Displays a motivational message encouraging upgrade to Pro
/// for unlimited AI reflections, then opens the paywall.
class BridgeAiLimit extends ConsumerWidget {
  const BridgeAiLimit({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryGreen = Color(0xFF6B9B7B);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.1),
            primaryGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.3),
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
                  color: primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI reflections used up this week',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Want deeper self-understanding every day?\n'
            'Upgrade to Pro for unlimited AI reflections, deep analysis, and weekly AI reports.',
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
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showPaywall(context),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Try Pro free for 7 days'),
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
