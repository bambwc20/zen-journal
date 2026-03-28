import 'package:flutter/material.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/models/streak_data.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/manage_streak.dart';

/// Displays the current streak count and earned badges.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.streakData,
    this.showBadges = true,
    this.compact = false,
  });

  final StreakData streakData;
  final bool showBadges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return _buildCompact(context, colorScheme);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: streakData.currentStreak > 0
                        ? Colors.orange
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streakData.currentStreak} Day Streak',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${streakData.totalDays} total days journaled',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (streakData.longestStreak > 0)
                  Column(
                    children: [
                      Text(
                        '${streakData.longestStreak}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Best',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (showBadges && streakData.badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: streakData.badges.map((badge) {
                  return Chip(
                    avatar: const Icon(Icons.emoji_events, size: 16),
                    label: Text(
                      ManageStreak.getBadgeDisplayName(badge),
                      style: theme.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: streakData.currentStreak > 0
                ? Colors.orange
                : colorScheme.onSurface.withValues(alpha: 0.3),
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${streakData.currentStreak}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
