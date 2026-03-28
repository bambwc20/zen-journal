import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_boilerplate/core/ads/ad_widgets.dart';
import 'package:flutter_boilerplate/core/ads/ad_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/journal_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';
import 'package:flutter_boilerplate/shared/widgets/empty_state.dart';

/// Journal list screen: full list of entries with search and AdBanner at bottom.
class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showAds = ref.watch(showAdsProvider);
    final searchQuery = ref.watch(journalSearchQueryProvider);
    final isSearchActive = searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search entries...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  ref.read(journalSearchQueryProvider.notifier).setQuery(value);
                },
              )
            : const Text('All Entries'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(journalSearchQueryProvider.notifier).clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isSearchActive
                ? _buildSearchResults(context)
                : _buildEntryList(context),
          ),
          // AdBanner at bottom for free users
          if (showAds) const AdBanner(),
        ],
      ),
    );
  }

  Widget _buildEntryList(BuildContext context) {
    final entriesAsync = ref.watch(journalEntriesStreamProvider);
    final theme = Theme.of(context);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.book_outlined,
            title: 'No Journal Entries',
            description: 'Start writing your first entry to begin your journaling journey.',
            actionLabel: 'Write Now',
            onAction: () => context.push('/editor'),
          );
        }

        return _buildEntriesListView(context, entries);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.error)),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final searchAsync = ref.watch(searchJournalEntriesProvider);
    final theme = Theme.of(context);
    final isPremiumUser = ref.watch(isPremiumProvider);

    return searchAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'No Results',
            description: 'Try a different search term.',
          );
        }

        // Free users: limited to last 30 days
        final filteredEntries = isPremiumUser
            ? entries
            : entries.where((e) {
                final thirtyDaysAgo =
                    DateTime.now().subtract(const Duration(days: 30));
                return e.createdAt.isAfter(thirtyDaysAgo);
              }).toList();

        if (filteredEntries.isEmpty && entries.isNotEmpty && !isPremiumUser) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Older Results Available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free search is limited to the last 30 days. '
                    'Upgrade to Pro for full-text search across all entries.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/paywall'),
                    child: const Text('Unlock Full Search'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildEntriesListView(context, filteredEntries);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEntriesListView(
    BuildContext context,
    List<JournalEntry> entries,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group entries by date
    final grouped = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final key = _formatGroupDate(entry.createdAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = grouped.keys.elementAt(groupIndex);
        final groupEntries = grouped[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                groupKey,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...groupEntries.map((entry) {
              final moodEmoji = entry.moodLevel >= 1 && entry.moodLevel <= 5
                  ? ZenJournalTheme.moodEmojis[entry.moodLevel - 1]
                  : '😐';

              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete, color: colorScheme.onError),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Entry?'),
                      content: const Text(
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  if (entry.id != null) {
                    ref
                        .read(journalRepositoryProvider)
                        .deleteEntry(entry.id!);
                    ref.invalidate(journalEntriesStreamProvider);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      entry.plainText.isEmpty
                          ? 'Untitled entry'
                          : entry.plainText.length > 80
                              ? '${entry.plainText.substring(0, 80)}...'
                              : entry.plainText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          _formatTime(entry.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.wordCount} words',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        if (entry.photos.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.photo_outlined,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${entry.photos.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/editor/${entry.id}'),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
