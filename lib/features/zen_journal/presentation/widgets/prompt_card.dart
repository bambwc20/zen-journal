import 'package:flutter/material.dart';

import 'package:flutter_boilerplate/features/zen_journal/domain/models/daily_prompt.dart';

/// A card that displays a daily writing prompt.
class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.prompt,
    this.onStartWriting,
    this.onSkip,
  });

  final DailyPrompt prompt;
  final VoidCallback? onStartWriting;
  final VoidCallback? onSkip;

  String _categoryIcon(String category) {
    return switch (category) {
      'self_reflection' => '🪞',
      'gratitude' => '🙏',
      'goals' => '🎯',
      'relationships' => '💝',
      'creativity' => '🎨',
      _ => '✨',
    };
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'self_reflection' => 'Self Reflection',
      'gratitude' => 'Gratitude',
      'goals' => 'Goals',
      'relationships' => 'Relationships',
      'creativity' => 'Creativity',
      _ => 'Prompt',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _categoryIcon(prompt.category),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  _categoryLabel(prompt.category),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  "Today's Prompt",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              prompt.text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onStartWriting,
                    child: const Text('Start Writing'),
                  ),
                ),
                if (onSkip != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onSkip,
                    child: const Text('Skip'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
