import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';

/// A 5-level mood selector widget with emoji icons.
/// Displays 5 mood options from very bad (1) to very good (5).
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.selectedLevel,
    required this.onMoodSelected,
    this.size = MoodSelectorSize.medium,
  });

  final int selectedLevel;
  final ValueChanged<int> onMoodSelected;
  final MoodSelectorSize size;

  double get _emojiSize {
    return switch (size) {
      MoodSelectorSize.small => 28,
      MoodSelectorSize.medium => 40,
      MoodSelectorSize.large => 56,
    };
  }

  double get _spacing {
    return switch (size) {
      MoodSelectorSize.small => 8,
      MoodSelectorSize.medium => 12,
      MoodSelectorSize.large => 16,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final level = index + 1;
        final isSelected = level == selectedLevel;
        final color = ZenJournalTheme.moodColors[index];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: _spacing / 2),
          child: Semantics(
            label: '${ZenJournalTheme.moodLabels[index]} mood',
            selected: isSelected,
            button: true,
            child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onMoodSelected(level);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? _emojiSize + 16 : _emojiSize + 8,
              height: isSelected ? _emojiSize + 16 : _emojiSize + 8,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ZenJournalTheme.moodEmojis[index],
                    style: TextStyle(fontSize: _emojiSize * 0.6),
                  ),
                  if (size != MoodSelectorSize.small && isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      ZenJournalTheme.moodLabels[index],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 8,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          ),
        );
      }),
    );
  }
}

enum MoodSelectorSize { small, medium, large }
