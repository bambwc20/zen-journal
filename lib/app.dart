import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'features/zen_journal/presentation/theme/zen_journal_theme.dart';
import 'features/zen_journal/presentation/routes.dart';
import 'features/zen_journal/presentation/screens/onboarding_screen.dart';
import 'features/zen_journal/presentation/screens/paywall_screen.dart';
import 'shared/widgets/error_boundary.dart';

/// Key used to check onboarding status in redirect.
const _kOnboardingCompleteKey = 'zen_journal_onboarding_complete';

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    // Check onboarding status on initial launch
    if (state.matchedLocation == '/') {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_kOnboardingCompleteKey) ?? false;
      if (!completed) {
        return '/onboarding';
      }
    }
    return null;
  },
  routes: [
    // ZenJournal feature routes (shell with bottom nav + sub-routes)
    ...zenJournalRoutes(),
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'ZenJournal',
      debugShowCheckedModeBanner: false,
      theme: ZenJournalTheme.light(),
      darkTheme: ZenJournalTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...FlutterQuillLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Custom error widget for release mode
        ErrorWidget.builder = (details) {
          return const ErrorScreen();
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
