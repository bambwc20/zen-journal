import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_boilerplate/shared/widgets/offline_banner.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/home_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/journal_editor_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/ai_reflection_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/calendar_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/journal_list_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/stats_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/settings_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/onboarding_screen.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/screens/paywall_screen.dart';

/// Shell scaffold with BottomNavigationBar for main tabs.
class _ZenJournalShellScaffold extends ConsumerWidget {
  const _ZenJournalShellScaffold({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

const _kTransitionDuration = Duration(milliseconds: 300);

CustomTransitionPage<void> _slideUpPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: _kTransitionDuration,
    reverseTransitionDuration: _kTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: _kTransitionDuration,
    reverseTransitionDuration: _kTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideRightPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: _kTransitionDuration,
    reverseTransitionDuration: _kTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// All routes for the ZenJournal feature.
/// Uses ShellRoute for bottom navigation with 4 main tabs.
List<RouteBase> zenJournalRoutes() {
  return [
    // Main shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _ZenJournalShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Home tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Calendar tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        // Stats tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        // Settings tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Journal editor (new or edit) — slide up transition
    GoRoute(
      path: '/editor/:id',
      pageBuilder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return _slideUpPage(
          key: state.pageKey,
          child: JournalEditorScreen(entryId: id),
        );
      },
    ),
    GoRoute(
      path: '/editor',
      pageBuilder: (context, state) {
        final moodStr = state.uri.queryParameters['mood'];
        final prompt = state.uri.queryParameters['prompt'];
        final mood = moodStr != null ? int.tryParse(moodStr) : null;
        return _slideUpPage(
          key: state.pageKey,
          child: JournalEditorScreen(
            initialMood: mood,
            initialPrompt: prompt,
          ),
        );
      },
    ),

    // AI reflection — fade transition
    GoRoute(
      path: '/reflection/:entryId',
      pageBuilder: (context, state) {
        final entryId =
            int.tryParse(state.pathParameters['entryId'] ?? '') ?? 0;
        return _fadePage(
          key: state.pageKey,
          child: AiReflectionScreen(entryId: entryId),
        );
      },
    ),

    // Journal list — slide from right
    GoRoute(
      path: '/journal-list',
      pageBuilder: (context, state) => _slideRightPage(
        key: state.pageKey,
        child: const JournalListScreen(),
      ),
    ),

    // Onboarding — fade transition
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _fadePage(
        key: state.pageKey,
        child: const ZenJournalOnboardingScreen(),
      ),
    ),
    // Paywall — slide up transition
    GoRoute(
      path: '/paywall',
      pageBuilder: (context, state) => _slideUpPage(
        key: state.pageKey,
        child: const ZenJournalPaywallScreen(),
      ),
    ),
  ];
}
