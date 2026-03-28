import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/prompt_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/streak_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/mood_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/journal_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/prompt_card.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/streak_badge.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/mood_selector.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/save_journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/bridge_streak.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/ad_placements.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/shimmer_loading.dart';

/// Home screen: Today's prompt, mood selector, quick record button, streak display.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with greeting and streak
            SliverAppBar(
              floating: true,
              title: Text(
                'ZenJournal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              actions: [
                _buildStreakBadge(ref),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting
                  _buildGreeting(context),
                  const SizedBox(height: 20),

                  // Today's mood section
                  _buildTodayMoodSection(context, ref),
                  const SizedBox(height: 20),

                  // Daily prompt card
                  _buildPromptSection(context, ref),
                  const SizedBox(height: 12),

                  // Native ad between prompt and stats (free users)
                  const NativePromptAd(),
                  const SizedBox(height: 12),

                  // Quick stats
                  _buildQuickStats(context, ref),
                  const SizedBox(height: 20),

                  // 7-day streak bridge (free users only)
                  _buildStreakBridge(ref),

                  // Recent entries preview
                  _buildRecentEntries(context, ref),
                  const SizedBox(height: 80), // Space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(context, ref),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Write'),
      ),
    );
  }

  Widget _buildStreakBadge(WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    return streakAsync.when(
      data: (streak) => StreakBadge(streakData: streak, compact: true),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Text(
      greeting,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildTodayMoodSection(BuildContext context, WidgetRef ref) {
    final todayMoodAsync = ref.watch(todayMoodProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            todayMoodAsync.when(
              data: (mood) {
                final currentLevel = mood?.level ?? 3;
                return MoodSelector(
                  selectedLevel: currentLevel,
                  onMoodSelected: (level) {
                    _navigateToEditor(context, ref, extraQuery: 'mood=$level');
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => MoodSelector(
                selectedLevel: 3,
                onMoodSelected: (level) {
                  _navigateToEditor(context, ref, extraQuery: 'mood=$level');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection(BuildContext context, WidgetRef ref) {
    final promptAsync = ref.watch(todayPromptProvider);

    return promptAsync.when(
      data: (prompt) => PromptCard(
        prompt: prompt,
        onStartWriting: () {
          _navigateToEditor(
            context,
            ref,
            extraQuery: 'prompt=${Uri.encodeComponent(prompt.text)}',
          );
        },
        onSkip: () {
          // Refresh to get next prompt
          ref.invalidate(todayPromptProvider);
        },
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return streakAsync.when(
      data: (streak) => Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              label: 'Current Streak',
              value: '${streak.currentStreak}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.emoji_events,
              iconColor: colorScheme.primary,
              label: 'Longest Streak',
              value: '${streak.longestStreak}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.calendar_today,
              iconColor: colorScheme.tertiary,
              label: 'Total Days',
              value: '${streak.totalDays}',
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: const [
          Expanded(child: StatCardSkeleton()),
          SizedBox(width: 12),
          Expanded(child: StatCardSkeleton()),
          SizedBox(width: 12),
          Expanded(child: StatCardSkeleton()),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStreakBridge(WidgetRef ref) {
    final isPremiumUser = ref.watch(isPremiumProvider);
    if (isPremiumUser) return const SizedBox.shrink();

    final streakAsync = ref.watch(currentStreakProvider);
    return streakAsync.when(
      data: (streak) {
        if (streak.currentStreak == 7) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: BridgeStreak(),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentEntries(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Entries',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/journal-list'),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        entriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 48,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No entries yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start your journaling journey today!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final recentEntries = entries.take(3).toList();
            return Column(
              children: recentEntries.map((entry) {
                final moodEmoji = entry.moodLevel >= 1 && entry.moodLevel <= 5
                    ? ZenJournalTheme.moodEmojis[entry.moodLevel - 1]
                    : '😐';
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Text(moodEmoji, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      entry.plainText.isEmpty
                          ? 'Untitled entry'
                          : entry.plainText.length > 60
                              ? '${entry.plainText.substring(0, 60)}...'
                              : entry.plainText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatDate(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/editor/${entry.id}'),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Column(
            children: const [
              EntryCardSkeleton(),
              SizedBox(height: 8),
              EntryCardSkeleton(),
            ],
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _navigateToEditor(
    BuildContext context,
    WidgetRef ref, {
    String? extraQuery,
  }) async {
    final isPremiumUser = ref.read(isPremiumProvider);
    if (!isPremiumUser) {
      final todayCount = await ref.read(todayEntryCountProvider.future);
      if (todayCount >= SaveJournalEntry.freeDailyEntryLimit) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Free users can write 1 entry per day. '
                'Upgrade to Pro for unlimited entries.',
              ),
              action: SnackBarAction(
                label: 'Upgrade',
                onPressed: () => context.push('/paywall'),
              ),
            ),
          );
        }
        return;
      }
    }
    if (context.mounted) {
      final path = extraQuery != null ? '/editor?$extraQuery' : '/editor';
      context.push(path);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
