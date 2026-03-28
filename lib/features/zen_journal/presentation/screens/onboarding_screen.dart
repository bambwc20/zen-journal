import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'paywall_screen.dart';

part 'onboarding_screen.g.dart';

/// Keys used to persist onboarding state.
const _kOnboardingCompleteKey = 'zen_journal_onboarding_complete';
const _kOnboardingGoalKey = 'zen_journal_onboarding_goal';
const _kReminderHourKey = 'zen_journal_reminder_hour';
const _kReminderMinuteKey = 'zen_journal_reminder_minute';

/// Provider that checks whether the user has completed onboarding.
@riverpod
Future<bool> onboardingComplete(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingCompleteKey) ?? false;
}

/// Marks onboarding as complete in shared_preferences.
Future<void> _markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingCompleteKey, true);
}

/// Saves the user's selected journaling goal.
Future<void> _saveGoal(String goal) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kOnboardingGoalKey, goal);
}

/// Saves the user's preferred reminder time.
Future<void> _saveReminderTime(int hour, int minute) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kReminderHourKey, hour);
  await prefs.setInt(_kReminderMinuteKey, minute);
}

/// ZenJournal onboarding screen.
///
/// 5-step onboarding: 3 intro pages + goal setting + notification time.
/// On completion, shows a soft paywall (7-day free trial) then navigates
/// to the main screen.
class ZenJournalOnboardingScreen extends ConsumerStatefulWidget {
  const ZenJournalOnboardingScreen({super.key});

  static const String routePath = '/onboarding';

  @override
  ConsumerState<ZenJournalOnboardingScreen> createState() =>
      _ZenJournalOnboardingScreenState();
}

class _ZenJournalOnboardingScreenState
    extends ConsumerState<ZenJournalOnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  String? _selectedGoal;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  static const _goals = [
    ('Daily Reflection', Icons.self_improvement, 'Understand yourself better through daily writing'),
    ('Mood Tracking', Icons.mood, 'Track and improve your emotional well-being'),
    ('Habit Building', Icons.local_fire_department, 'Build a consistent journaling habit'),
    ('Stress Relief', Icons.spa, 'Use writing as a tool for stress management'),
    ('Gratitude', Icons.favorite, 'Cultivate gratitude and positivity'),
  ];

  static const _totalPages = 5; // 3 intro + goal + notification

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLast = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _onOnboardingFinished(context),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  // Step 1: AI Reflection intro
                  _buildIntroPage(
                    icon: Icons.auto_awesome,
                    iconColor: const Color(0xFF6B9B7B),
                    title: 'AI That Understands Your Journal',
                    description:
                        'We analyze emotional patterns from your daily entries\n'
                        'and deliver personalized AI reflections.\n'
                        'Get deeper insights based on 7 days of context.',
                  ),
                  // Step 2: Mood tracking
                  _buildIntroPage(
                    icon: Icons.insights,
                    iconColor: const Color(0xFFF5A623),
                    title: 'Track Moods, Discover Patterns',
                    description:
                        'Log your daily mood with 5 emoji levels,\n'
                        'then explore weekly and monthly mood charts.\n'
                        'Tag correlations reveal what drives how you feel.',
                  ),
                  // Step 3: Streak
                  _buildIntroPage(
                    icon: Icons.local_fire_department,
                    iconColor: const Color(0xFFE85D4A),
                    title: 'Build a Daily Writing Habit',
                    description:
                        'Stay motivated with streaks and milestone badges.\n'
                        'Set gentle reminders at your preferred time.\n'
                        'Aim for 7-day, 30-day, and 100-day milestones!',
                  ),
                  // Step 4: Goal setting
                  _buildGoalPage(theme, colorScheme),
                  // Step 5: Notification time
                  _buildReminderPage(theme, colorScheme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: isLast
                        ? () => _onOnboardingFinished(context)
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: iconColor),
          const SizedBox(height: 40),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'What is your journaling goal?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your experience',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...List.generate(_goals.length, (i) {
            final (label, icon, subtitle) = _goals[i];
            final isSelected = _selectedGoal == label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _selectedGoal = label);
                    _saveGoal(label);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : null,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.7)
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.onPrimaryContainer,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReminderPage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'When should we remind you?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Set a daily reminder to build your writing habit',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
              );
              if (picked != null) {
                setState(() => _reminderTime = picked);
                _saveReminderTime(picked.hour, picked.minute);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 32,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _reminderTime.format(context),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to change time',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You can always change this in Settings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Called when the user completes or skips onboarding.
  Future<void> _onOnboardingFinished(BuildContext context) async {
    // Save default reminder time if not explicitly changed
    await _saveReminderTime(_reminderTime.hour, _reminderTime.minute);

    // Show soft paywall as bottom sheet modal
    if (context.mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const FractionallySizedBox(
          heightFactor: 0.92,
          child: ZenJournalPaywallScreen(),
        ),
      );
    }

    // Mark onboarding as complete regardless of paywall result
    await _markOnboardingComplete();

    // Navigate to main screen
    if (context.mounted) {
      context.go('/');
    }
  }
}
