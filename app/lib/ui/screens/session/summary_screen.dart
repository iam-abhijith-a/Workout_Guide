import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/muscle_map.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/session.dart';
import '../../../state/providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/body_map.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';

/// The post-workout summary.
///
/// This is the one screen in the app that is allowed to be a little
/// ceremonious. It is seen a few times a week at most, always at a moment of
/// genuine accomplishment, and it is the thing that makes someone come back.
/// Numbers roll up rather than appear, and the muscles they just trained light
/// up on the figure -- turning an abstract set count into something they can see.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final repo = ref.watch(exerciseRepoProvider);
    final streak = ref.watch(streakProvider);
    final thisWeek = ref.watch(sessionsThisWeekProvider);
    final history = ref.watch(historyProvider);

    // Everything the session actually touched, primary and secondary.
    final primary = <MuscleRegion>{};
    final secondary = <MuscleRegion>{};
    for (final log in session.exercises) {
      if (log.role == PlanRole.warmup || log.role == PlanRole.cooldown) {
        continue;
      }
      if (log.completedSets == 0) continue;
      final exercise = repo.byId(log.exerciseId);
      if (exercise == null) continue;
      primary.addAll(regionsForMuscle(exercise.target));
      for (final muscle in exercise.secondary) {
        secondary.addAll(regionsForMuscle(muscle));
      }
    }
    secondary.removeAll(primary);

    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isFirst = history.length == 1;

    return FBackdrop(
      child: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              FSpace.gutter,
              topInset + FSpace.x4l,
              FSpace.gutter,
              bottomInset + FSpace.x3l,
            ),
            children: [
              FadeSlideIn(
                child: Text(
                  isFirst ? 'First one done.' : 'Session complete.',
                  style: FType.h1,
                ),
              ),
              const SizedBox(height: FSpace.sm),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  isFirst
                      ? 'The hardest one is behind you.'
                      : '${session.dayTitle} · ${session.dayFocus}',
                  style: FType.body,
                ),
              ),

              const SizedBox(height: FSpace.x3l),

              // -- Numbers ------------------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: FCard(
                  padding: const EdgeInsets.all(FSpace.xl),
                  child: Row(
                    children: [
                      Expanded(
                        child: _RollingStat(
                          value: session.duration.inMinutes.toDouble(),
                          label: 'Minutes',
                          delay: 260,
                        ),
                      ),
                      _Divider(),
                      Expanded(
                        child: _RollingStat(
                          value: session.totalSetsDone.toDouble(),
                          label: 'Sets',
                          delay: 340,
                          accent: true,
                        ),
                      ),
                      _Divider(),
                      Expanded(
                        child: _RollingStat(
                          value: session.totalVolume,
                          label: 'Lifted',
                          suffix: profile.units.suffix,
                          delay: 420,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FSpace.lg),

              // -- What you trained ---------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: FCard(
                  padding: const EdgeInsets.all(FSpace.xl),
                  child: Column(
                    children: [
                      Text('Muscles trained', style: FType.caption),
                      const SizedBox(height: FSpace.lg),
                      BodyMap(
                        primary: primary,
                        secondary: secondary,
                        height: 210,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FSpace.lg),

              // -- Consistency --------------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: FCard(
                  color: FColors.wash(FColors.orange),
                  borderColor: FColors.washBorder(FColors.orange),
                  child: Row(
                    children: [
                      ProgressRing(
                        progress: thisWeek.length / profile.daysPerWeek,
                        size: 40,
                        strokeWidth: 3.5,
                        color: FColors.orange,
                        trackColor: FColors.washBorder(FColors.orange),
                        duration: const Duration(milliseconds: 1100),
                        child: const FIcon(
                          FIcons.flame,
                          size: 16,
                          color: FColors.orange,
                        ),
                      ),
                      const SizedBox(width: FSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _consistencyTitle(
                                thisWeek.length,
                                profile.daysPerWeek,
                                streak,
                              ),
                              style: FType.h3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _consistencyBody(
                                thisWeek.length,
                                profile.daysPerWeek,
                              ),
                              style: FType.small.copyWith(
                                color: FColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: FSpace.lg),

              // -- Per-exercise breakdown ---------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: FSection(
                  title: 'What you did',
                  padding: EdgeInsets.zero,
                  child: FCard(
                    padding: const EdgeInsets.all(FSpace.lg),
                    child: Column(
                      children: [
                        for (var i = 0; i < session.exercises.length; i++)
                          if (session.exercises[i].completedSets > 0)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == session.exercises.length - 1
                                    ? 0
                                    : FSpace.md,
                              ),
                              child: _ExerciseSummaryRow(
                                log: session.exercises[i],
                                units: profile.units,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: FSpace.x3l),

              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: FButton(
                  label: 'Done',
                  variant: FButtonVariant.primary,
                  size: FButtonSize.lg,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _consistencyTitle(int done, int target, int streak) {
    if (done >= target) return 'Week complete';
    if (streak > 1) return '$streak weeks in a row';
    return '$done of $target this week';
  }

  static String _consistencyBody(int done, int target) {
    if (done >= target) return 'Target hit. Rest is part of the plan.';
    final left = target - done;
    return '$left to go. Rest a day in between.';
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    color: FColors.border,
    margin: const EdgeInsets.symmetric(horizontal: FSpace.sm),
  );
}

/// A number that counts up to its value.
///
/// Worth the motion here specifically because these figures are an
/// accumulation the user has just earned -- the roll is the point.
class _RollingStat extends StatelessWidget {
  const _RollingStat({
    required this.value,
    required this.label,
    required this.delay,
    this.suffix,
    this.accent = false,
  });

  final double value;
  final String label;
  final int delay;
  final String? suffix;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeSlideIn(
          delay: Duration(milliseconds: delay),
          offset: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: CountUp(
                  value: value,
                  delay: Duration(milliseconds: delay),
                  duration: const Duration(milliseconds: 950),
                  style: FType.numLarge.copyWith(
                    color: accent ? FColors.primary : FColors.text,
                  ),
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: FType.caption.copyWith(color: FColors.textFaint),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FType.caption.copyWith(color: FColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ExerciseSummaryRow extends StatelessWidget {
  const _ExerciseSummaryRow({required this.log, required this.units});

  final ExerciseLog log;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final weights = log.sets
        .where((s) => s.done && (s.weight ?? 0) > 0)
        .map((s) => s.weight!)
        .toList();
    final topWeight = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        const FIcon(FIcons.check, size: 13, color: FColors.primary),
        const SizedBox(width: FSpace.md),
        Expanded(
          child: Text(
            log.name,
            style: FType.caption.copyWith(color: FColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: FSpace.sm),
        Text(
          topWeight == null
              ? '${log.completedSets} set${log.completedSets == 1 ? '' : 's'}'
              : '${log.completedSets} × ${_trim(topWeight)}${units.suffix}',
          style: FType.num.copyWith(color: FColors.textMuted),
        ),
      ],
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
