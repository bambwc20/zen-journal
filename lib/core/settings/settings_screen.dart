import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('테마'),
              subtitle: Text(_themeModeLabel(themeMode)),
              onTap: () => ref.read(appThemeModeProvider.notifier).toggle(),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('알림'),
              value: settings['notifications_enabled'] as bool,
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setBool('notifications_enabled', value),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 정보'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'App',
                applicationVersion: '1.0.0',
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '시스템',
      ThemeMode.light => '라이트',
      ThemeMode.dark => '다크',
    };
  }
}
