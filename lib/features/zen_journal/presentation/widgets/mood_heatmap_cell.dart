import 'package:flutter/material.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';

/// A calendar cell that displays a mood-colored background for heatmap view.
/// Used as a custom day builder in TableCalendar.
class MoodHeatmapCell extends StatelessWidget {
  const MoodHeatmapCell({
    super.key,
    required this.day,
    this.moodLevel,
    this.isSelected = false,
    this.isToday = false,
  });

  final DateTime day;

  /// Mood level 1-5, or null if no mood recorded.
  final int? moodLevel;
  final bool isSelected;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color? backgroundColor;
    Color textColor = colorScheme.onSurface;

    if (moodLevel != null && moodLevel! >= 1 && moodLevel! <= 5) {
      final moodColor = ZenJournalTheme.moodColors[moodLevel! - 1];
      backgroundColor = moodColor.withValues(alpha: 0.3);
      textColor = colorScheme.onSurface;
    }

    if (isSelected) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isToday) {
      backgroundColor = backgroundColor ?? colorScheme.primary.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: isToday || isSelected ? FontWeight.w700 : null,
          ),
        ),
      ),
    );
  }
}
