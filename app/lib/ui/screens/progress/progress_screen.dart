import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/muscle_map.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/session.dart';
import '../../../state/providers.dart';
import '../../../state/session_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/indicators.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../root_screen.dart';
import 'session_detail_screen.dart';

/// Progress.
///
/// Leads with consistency, not with weight lifted. In the first few months
/// almost all of a beginner's progress is showing up and learning the
/// movements, and a screen that only measures kilos tells them they are failing
/// when they are not.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final stats = ref.watch(progressStatsProvider);
    final profile = ref.watch(profileProvider);
    final streak = ref.watch(streakProvider);

    if (history.isEmpty) {
      return FScreen(
        title: 'Progress',
        bottomPadding: kTabBarInset,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FEmptyState(
              icon: FIcons.chart,
              tone: FColors.teal,
              title: 'Nothing here yet',
              message: 'Finish a workout and it shows up here.',
            ),
          ),
        ],
      );
    }

    return FScreen(
      title: 'Progress',
      subtitle:
          '${stats.totalSessions} session'
          '${stats.totalSessions == 1 ? '' : 's'} logged',
      bottomPadding: kTabBarInset + FSpace.xxl,
      slivers: [
        // -- Headline numbers -------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            child: FadeSlideIn(
              child: FCard(
                padding: const EdgeInsets.all(FSpace.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Week streak',
                        value: '$streak',
                        accent: streak > 0,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Sets',
                        value: '${stats.totalSets}',
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Time',
                        value: _formatHours(stats.totalMinutes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // -- Volume over time --------------------------------------------------
        // Needs at least two weeks to be a trend rather than a single bar, and
        // its surrounding spacing has to disappear with it.
        if (stats.volumeByWeek.length > 1) ...[
          const SliverToBoxAdapter(child: SizedBox(height: FSpace.section)),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: FSection(
                title: 'Weekly volume',
                subtitle:
                    'Total weight moved each week — sets × reps × weight.',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FSpace.gutter,
                  ),
                  child: FCard(
                    padding: const EdgeInsets.all(FSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            CountUp(
                              value: stats.volumeByWeek.last.volume,
                              style: FType.numLarge,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.units.suffix} this week',
                              style: FType.caption.copyWith(
                                color: FColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: FSpace.xl),
                        VolumeChart(
                          values: [
                            for (final week in stats.volumeByWeek.take(12))
                              week.volume,
                          ],
                          labels: [
                            for (final week in stats.volumeByWeek.take(12))
                              '${week.week.day}/${week.week.month}',
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.section)),

        // -- Balance -----------------------------------------------------------
        // The most behaviour-changing chart in the app. Beginners overtrain what
        // they can see in the mirror; putting chest next to back makes the
        // imbalance obvious without anyone having to lecture them about it.
        if (stats.setsByBodyPart.isNotEmpty)
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: FSection(
                title: 'Muscle balance',
                subtitle: 'Sets per body part. Big gaps are worth a look.',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FSpace.gutter,
                  ),
                  child: FCard(
                    padding: const EdgeInsets.all(FSpace.lg),
                    child: BalanceBars(
                      colorOf: (label) => bodyPartColor(label.toLowerCase()),
                      data: () {
                        final entries = stats.setsByBodyPart.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        return [
                          for (final e in entries)
                            (label: _titleCase(e.key), value: e.value),
                        ];
                      }(),
                    ),
                  ),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        // -- History -----------------------------------------------------------
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: FSection(title: 'History', child: const SizedBox.shrink()),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          sliver: SliverList.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: FSpace.sm),
            itemBuilder: (context, i) =>
                _HistoryRow(session: history[i], units: profile.units),
          ),
        ),
      ],
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h';
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session, required this.units});

  final WorkoutSession session;
  final Units units;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final date = session.startedAt;
    return FCard(
      padding: const EdgeInsets.all(FSpace.md),
      onTap: () => Navigator.of(context).push(
        FPageRoute<void>(builder: (_) => SessionDetailScreen(session: session)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: FColors.muted,
              borderRadius: FRadius.rMd,
              border: Border.all(color: FColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: FType.num.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _months[date.month - 1],
                  style: FType.caption.copyWith(color: FColors.textFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.dayTitle, style: FType.h3),
                const SizedBox(height: 3),
                Text(
                  '${session.totalSetsDone} '
                  'set${session.totalSetsDone == 1 ? '' : 's'} · '
                  '${session.duration.inMinutes} min'
                  '${session.totalVolume > 0 ? ' · ${session.totalVolume.round()}${units.suffix}' : ''}',
                  style: FType.caption.copyWith(color: FColors.textMuted),
                ),
              ],
            ),
          ),
          const FIcon(FIcons.chevronRight, size: 15, color: FColors.textFaint),
        ],
      ),
    );
  }
}
