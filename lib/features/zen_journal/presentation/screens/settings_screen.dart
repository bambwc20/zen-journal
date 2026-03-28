import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_boilerplate/core/theme/theme_provider.dart';
import 'package:flutter_boilerplate/core/subscription/entitlement.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/backup_data.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings screen: backup, notification time, theme toggle,
/// subscription management link.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(appThemeModeProvider);
    final isPremiumUser = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account section
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPremiumUser
                    ? Colors.amber.withValues(alpha: 0.15)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPremiumUser ? Icons.star : Icons.star_border,
                color: isPremiumUser ? Colors.amber : colorScheme.primary,
              ),
            ),
            title: Text(isPremiumUser ? 'Pro Member' : 'Free Plan'),
            subtitle: Text(
              isPremiumUser
                  ? 'All premium features unlocked'
                  : 'Upgrade for unlimited access',
            ),
            trailing: isPremiumUser
                ? null
                : FilledButton(
                    onPressed: () => context.push('/paywall'),
                    child: const Text('Upgrade'),
                  ),
            onTap: () => context.push('/paywall'),
          ),
          const Divider(),

          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _themeModeIcon(themeMode),
                color: colorScheme.primary,
              ),
            ),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () {
              ref.read(appThemeModeProvider.notifier).toggle();
            },
          ),
          const Divider(),

          // Notifications section
          _buildSectionHeader(context, 'Notifications'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: colorScheme.primary,
              ),
            ),
            title: const Text('Daily Reminder'),
            subtitle: const Text('Set your preferred journaling time'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReminderTimePicker(context);
            },
          ),
          const Divider(),

          // Backup section
          _buildSectionHeader(context, 'Data & Backup'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.backup_outlined,
                color: colorScheme.primary,
              ),
            ),
            title: const Text('Local Backup'),
            subtitle: const Text('Create an encrypted backup file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _createBackup(context, ref),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restore,
                color: colorScheme.primary,
              ),
            ),
            title: const Text('Restore Backup'),
            subtitle: const Text('Restore from a backup file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: implement file picker for restore
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          ),
          EntitlementGate(
            placeholder: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: Colors.amber),
              ),
              title: const Text('Cloud Backup'),
              subtitle: const Text('Auto backup to Google Drive / iCloud'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Pro',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/paywall'),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: colorScheme.primary,
                ),
              ),
              title: const Text('Cloud Backup'),
              subtitle: const Text('Auto backup to Google Drive / iCloud'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: implement cloud backup settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
          ),
          const Divider(),

          // Export section (premium)
          _buildSectionHeader(context, 'Export'),
          EntitlementGate(
            placeholder: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.amber),
              ),
              title: const Text('Export Data'),
              subtitle: const Text('PDF, TXT, JSON, CSV'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Pro',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/paywall'),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: colorScheme.primary,
                ),
              ),
              title: const Text('Export Data'),
              subtitle: const Text('TXT, JSON, CSV'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportOptions(context, ref),
            ),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: colorScheme.primary),
            ),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
            ),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // TODO: open privacy policy URL
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description_outlined, color: colorScheme.primary),
            ),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // TODO: open terms URL
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  IconData _themeModeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
    };
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  Future<void> _showReminderTimePicker(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHour = prefs.getInt('zen_journal_reminder_hour') ?? 21;
    final savedMinute = prefs.getInt('zen_journal_reminder_minute') ?? 0;

    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: savedHour, minute: savedMinute),
    );
    if (time != null && context.mounted) {
      await prefs.setInt('zen_journal_reminder_hour', time.hour);
      await prefs.setInt('zen_journal_reminder_minute', time.minute);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${time.format(context)}'),
          ),
        );
      }
    }
  }

  Future<void> _showExportOptions(BuildContext context, WidgetRef ref) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Export Format',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Plain Text (.txt)'),
              onTap: () => Navigator.pop(context, 'txt'),
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('JSON (.json)'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV (.csv)'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (format == null || !context.mounted) return;

    try {
      final repo = ref.read(journalRepositoryProvider);
      final entries = await repo.getAllEntries();

      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No entries to export')),
          );
        }
        return;
      }

      final backup = ref.read(backupDataProvider);
      final file = switch (format) {
        'txt' => await backup.exportToTxt(entries),
        'json' => await backup.exportToJson(entries),
        'csv' => await backup.exportToCsv(entries),
        _ => throw Exception('Unknown format'),
      };

      await backup.shareFile(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    try {
      final backup = ref.read(backupDataProvider);
      final path = await backup.createLocalBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }
}
