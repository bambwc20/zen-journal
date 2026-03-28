import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/mood_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/streak_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/streak_badge.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_stats.dart';

/// Stats screen: mood graphs (fl_chart), streak statistics, tag analysis.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyView(context),
          _buildMonthlyView(context),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(BuildContext context) {
    final statsAsync = ref.watch(weeklyMoodStatsProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak card
          streakAsync.when(
            data: (streak) => StreakBadge(streakData: streak),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Weekly mood chart
          statsAsync.when(
            data: (stats) => _buildMoodSection(context, stats, 'This Week'),
            loading: () => const Card(
              child: SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Weekly mood line chart
          _buildWeeklyLineChart(context),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context) {
    final statsAsync = ref.watch(monthlyMoodStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsAsync.when(
            data: (stats) => _buildMoodSection(context, stats, 'This Month'),
            loading: () => const Card(
              child: SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(
    BuildContext context,
    MoodStats stats,
    String periodLabel,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (stats.totalEntries == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'No mood data for $periodLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start journaling to see your mood trends',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average mood card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stats.averageMood.toStringAsFixed(1),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '/ 5.0',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Average Mood',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _getMoodEmoji(stats.averageMood),
                  style: const TextStyle(fontSize: 48),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Mood distribution bar chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Distribution',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalEntries} entries recorded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildMoodDistributionChart(stats),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tag frequency
        if (stats.tagFrequency.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Tags',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...stats.tagFrequency.entries
                      .toList()
                      .sorted((a, b) => b.value.compareTo(a.value))
                      .take(10)
                      .map((entry) {
                    final maxCount = stats.tagFrequency.values
                        .reduce((a, b) => a > b ? a : b);
                    final ratio = entry.value / maxCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMoodDistributionChart(MoodStats stats) {
    final maxValue = stats.moodDistribution.values.isEmpty
        ? 1
        : stats.moodDistribution.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() + 1,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final level = group.x + 1;
              return BarTooltipItem(
                '${ZenJournalTheme.moodLabels[level - 1]}\n${rod.toY.toInt()} entries',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < 5) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      ZenJournalTheme.moodEmojis[index],
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(5, (index) {
          final level = index + 1;
          final count = stats.moodDistribution[level] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: ZenJournalTheme.moodColors[index],
                width: 28,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWeeklyLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    final moodsAsync = ref.watch(moodsByDateRangeProvider(start, end));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Trend',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: moodsAsync.when(
                data: (moods) {
                  if (moods.isEmpty) {
                    return Center(
                      child: Text(
                        'Not enough data yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }

                  final spots = <FlSpot>[];
                  for (final mood in moods.reversed) {
                    final dayIndex =
                        mood.date.difference(start).inDays.toDouble();
                    if (dayIndex >= 0 && dayIndex < 7) {
                      spots.add(FlSpot(dayIndex, mood.level.toDouble()));
                    }
                  }

                  if (spots.isEmpty) {
                    return Center(
                      child: Text(
                        'Not enough data yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }

                  return LineChart(
                    LineChartData(
                      minY: 0.5,
                      maxY: 5.5,
                      minX: 0,
                      maxX: 6,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final level = spot.y.toInt();
                              final emoji = level >= 1 && level <= 5
                                  ? ZenJournalTheme.moodEmojis[level - 1]
                                  : '';
                              return LineTooltipItem(
                                '$emoji ${ZenJournalTheme.moodLabels[level - 1]}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
                              ];
                              final idx = value.toInt();
                              if (idx >= 0 && idx < 7) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    days[idx],
                                    style: theme.textTheme.labelSmall,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 1 && idx <= 5) {
                                return Text(
                                  ZenJournalTheme.moodEmojis[idx - 1],
                                  style: const TextStyle(fontSize: 14),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colorScheme.primary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final level = spot.y.toInt();
                              final color = level >= 1 && level <= 5
                                  ? ZenJournalTheme.moodColors[level - 1]
                                  : colorScheme.primary;
                              return FlDotCirclePainter(
                                radius: 5,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(double average) {
    if (average < 1.5) return ZenJournalTheme.moodEmojis[0];
    if (average < 2.5) return ZenJournalTheme.moodEmojis[1];
    if (average < 3.5) return ZenJournalTheme.moodEmojis[2];
    if (average < 4.5) return ZenJournalTheme.moodEmojis[3];
    return ZenJournalTheme.moodEmojis[4];
  }
}

extension _SortedExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final copy = List<T>.of(this);
    copy.sort(compare);
    return copy;
  }
}
