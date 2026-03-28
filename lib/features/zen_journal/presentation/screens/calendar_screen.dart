import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/mood_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/journal_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/mood_heatmap_cell.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';

/// Calendar screen with table_calendar monthly view and mood heatmap.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final heatmapAsync = ref.watch(moodHeatmapDataProvider(monthStart));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          // Calendar with mood heatmap
          heatmapAsync.when(
            data: (heatmap) => _buildCalendar(context, heatmap),
            loading: () => _buildCalendar(context, {}),
            error: (_, __) => _buildCalendar(context, {}),
          ),

          // Mood legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ZenJournalTheme.moodColors[index]
                              .withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ZenJournalTheme.moodEmojis[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const Divider(),

          // Selected day entries
          Expanded(
            child: _selectedDay != null
                ? _buildDayEntries(context)
                : Center(
                    child: Text(
                      'Select a day to see entries',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    Map<DateTime, int> heatmap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary, width: 1.5),
        ),
        todayTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        formatButtonTextStyle: theme.textTheme.labelSmall!,
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final dateKey = DateTime(day.year, day.month, day.day);
          final moodLevel = heatmap[dateKey];
          return MoodHeatmapCell(day: day, moodLevel: moodLevel);
        },
        todayBuilder: (context, day, focusedDay) {
          final dateKey = DateTime(day.year, day.month, day.day);
          final moodLevel = heatmap[dateKey];
          return MoodHeatmapCell(
            day: day,
            moodLevel: moodLevel,
            isToday: true,
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          final dateKey = DateTime(day.year, day.month, day.day);
          final moodLevel = heatmap[dateKey];
          return MoodHeatmapCell(
            day: day,
            moodLevel: moodLevel,
            isSelected: true,
          );
        },
      ),
    );
  }

  Widget _buildDayEntries(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDate = _selectedDay!;
    final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final end = start.add(const Duration(days: 1));
    final entriesAsync = ref.watch(entriesByDateRangeProvider(start, end));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_add_outlined,
                  size: 48,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'No entries for this day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => context.push('/editor'),
                  child: const Text('Write Now'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final moodEmoji = entry.moodLevel >= 1 && entry.moodLevel <= 5
                ? ZenJournalTheme.moodEmojis[entry.moodLevel - 1]
                : '😐';

            return Card(
              child: ListTile(
                leading: Text(moodEmoji, style: const TextStyle(fontSize: 28)),
                title: Text(
                  entry.plainText.isEmpty
                      ? 'Untitled entry'
                      : entry.plainText.length > 80
                          ? '${entry.plainText.substring(0, 80)}...'
                          : entry.plainText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${entry.wordCount} words',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/editor/${entry.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Error loading entries',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }
}
