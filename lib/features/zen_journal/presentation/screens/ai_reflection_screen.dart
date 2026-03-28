import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_boilerplate/core/subscription/entitlement.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/ai_reflection.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/get_ai_reflection.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/ai_reflection_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/ad_placements.dart';

/// AI Reflection screen: shows 3 types of AI-generated reflection,
/// remaining free count, and premium upsell.
class AiReflectionScreen extends ConsumerStatefulWidget {
  const AiReflectionScreen({
    super.key,
    required this.entryId,
  });

  final int entryId;

  @override
  ConsumerState<AiReflectionScreen> createState() =>
      _AiReflectionScreenState();
}

class _AiReflectionScreenState extends ConsumerState<AiReflectionScreen> {
  bool _isGenerating = false;
  AiReflection? _reflection;
  String? _errorMessage;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _loadReflection();
  }

  Future<void> _loadReflection() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _limitReached = false;
    });

    try {
      final useCase = ref.read(getAiReflectionProvider);
      final reflection = await useCase.execute(widget.entryId);
      if (mounted) {
        setState(() {
          _reflection = reflection;
          _isGenerating = false;
        });
      }
    } on AiReflectionLimitReachedException catch (e) {
      if (mounted) {
        setState(() {
          _limitReached = true;
          _errorMessage = e.toString();
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate reflection. Please try again.';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremiumUser = ref.watch(isPremiumProvider);
    final remainingAsync = ref.watch(remainingFreeReflectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Reflection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Remaining free reflections banner
            if (!isPremiumUser)
              remainingAsync.when(
                data: (remaining) => _buildRemainingBanner(
                  context,
                  remaining,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

            if (!isPremiumUser) const SizedBox(height: 16),

            // Loading state
            if (_isGenerating) _buildLoadingState(context),

            // Error state
            if (_errorMessage != null && !_isGenerating)
              _buildErrorState(context),

            // Limit reached state
            if (_limitReached && !_isGenerating)
              _buildLimitReachedState(context),

            // Reflection content
            if (_reflection != null && !_isGenerating) ...[
              _buildReflectionCard(
                context,
                icon: Icons.psychology,
                iconColor: const Color(0xFF7B68EE),
                title: 'Emotion Analysis',
                content: _reflection!.emotionAnalysis,
              ),
              const SizedBox(height: 16),
              _buildReflectionCard(
                context,
                icon: Icons.insights,
                iconColor: const Color(0xFF20B2AA),
                title: 'Pattern Insight',
                content: _reflection!.patternInsight,
              ),
              const SizedBox(height: 16),
              _buildReflectionCard(
                context,
                icon: Icons.lightbulb_outline,
                iconColor: const Color(0xFFFFB347),
                title: 'Action Suggestion',
                content: _reflection!.actionSuggestion,
              ),
              const SizedBox(height: 24),

              // Weekly report (premium only)
              if (isPremiumUser)
                _buildWeeklyReportSection(context)
              else
                _buildPremiumUpsell(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingBanner(BuildContext context, int remaining) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLow = remaining <= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLow
            ? colorScheme.error.withValues(alpha: 0.1)
            : colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isLow ? Icons.warning_amber_rounded : Icons.auto_awesome,
            color: isLow ? colorScheme.error : colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              remaining > 0
                  ? '$remaining free reflection${remaining == 1 ? '' : 's'} left this week'
                  : 'No free reflections left this week',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isLow ? colorScheme.error : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (remaining <= 0)
            TextButton(
              onPressed: () => context.push('/paywall'),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating your AI reflection...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing your journal entry with context',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadReflection,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitReachedState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Weekly Limit Reached',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You've used all 2 free AI reflections this week. "
              'Upgrade to Pro for unlimited reflections and deeper insights.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/paywall'),
              child: const Text('Unlock Unlimited Reflections'),
            ),
            const SizedBox(height: 8),
            RewardedAdButton(
              label: 'Watch Ad for 1 Free Reflection',
              onRewardEarned: () {
                // Grant extra reflection by retrying
                _loadReflection();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReportSection(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final reportAsync = ref.watch(weeklyReportProvider(weekStartDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Weekly Report',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        reportAsync.when(
          data: (report) {
            if (report == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Not enough entries this week for a report. Keep journaling!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.summary, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text(
                      'Mood Trend: ${report.moodTrend}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (report.keyInsights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...report.keyInsights.map(
                        (insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('  - '),
                              Expanded(
                                child: Text(
                                  insight,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPremiumUpsell(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EntitlementGate(
      placeholder: Card(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock Weekly AI Reports',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get deep weekly insights, mood trends, and personalized suggestions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push('/paywall'),
                child: const Text('Try Pro Free'),
              ),
            ],
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
