import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/muscle_map.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/plan.dart';
import '../../../state/providers.dart';
import '../../../state/session_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../root_screen.dart';
import '../session/session_screen.dart';
import 'day_screen.dart';
import 'resume_card.dart';
import 'week_strip.dart';

/// The week.
///
/// Explains the plan as much as it lists it: what the split is, why it was
/// chosen, and what each day is for. A beginner who understands the shape of
/// their week is far more likely to follow it than one handed a table.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    final profile = ref.watch(profileProvider);
    final nextIndex = ref.watch(nextDayIndexProvider);
    final active = ref.watch(sessionProvider);
    final streak = ref.watch(streakProvider);
    final thisWeek = ref.watch(sessionsThisWeekProvider);

    if (plan == null) {
      return FScreen(
        title: 'Plan',
        bottomPadding: kTabBarInset,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FEmptyState(
              icon: FIcons.calendar,
              tone: FColors.blue,
              title: 'No plan yet',
              message: 'Build one from your answers.',
              action: FButton(
                label: 'Build my plan',
                variant: FButtonVariant.primary,
                onPressed: () => ref.read(planProvider.notifier).build(profile),
              ),
            ),
          ),
        ],
      );
    }

    return FScreen(
      title: 'Your plan',
      subtitle: plan.name,
      bottomPadding: kTabBarInset + FSpace.xxl,
      actions: [
        FIconButton(
          icon: const FIcon(FIcons.swap),
          semanticLabel: 'Rebuild plan',
          onPressed: () => _confirmRegenerate(context, ref),
        ),
      ],
      slivers: [
        // -- A workout left running -------------------------------------------
        // First thing on the page while it is true, and gone the rest of the
        // time. Every Start button below is disabled while a session is live.
        if (active != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              child: FadeSlideIn(child: ResumeCard(session: active)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),
        ],

        // -- This week --------------------------------------------------------
        // The plan is written in weeks, so how far into this one you are
        // belongs next to it rather than two tabs away.
        SliverToBoxAdapter(
          child: FadeSlideIn(
            child: FSection(
              title: 'This week',
              action: streak > 0
                  ? Row(
                      children: [
                        const FIcon(
                          FIcons.flame,
                          size: 14,
                          color: FColors.orange,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$streak week${streak == 1 ? '' : 's'}',
                          style: FType.caption.copyWith(color: FColors.orange),
                        ),
                      ],
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
                child: WeekStrip(
                  target: profile.daysPerWeek,
                  sessions: thisWeek,
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        // -- Why this plan ----------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            child: FadeSlideIn(
              child: FCard(
                color: FColors.muted,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: FIcon(
                        FIcons.info,
                        size: 15,
                        color: FColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: FSpace.md),
                    Expanded(
                      child: Text(
                        plan.description,
                        style: FType.small.copyWith(
                          color: FColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        // -- Days -------------------------------------------------------------
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          sliver: SliverList.separated(
            itemCount: plan.days.length,
            separatorBuilder: (_, __) => const SizedBox(height: FSpace.md),
            itemBuilder: (context, i) => FadeSlideIn(
              delay: staggerDelay(
                i,
                baseDelay: const Duration(milliseconds: 60),
              ),
              child: _DayCard(
                day: plan.days[i],
                dayNumber: i + 1,
                isNext: i == nextIndex,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        // -- Rest days --------------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: FCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: FIcon(
                        FIcons.timer,
                        size: 16,
                        color: FColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: FSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rest days are training', style: FType.h3),
                          const SizedBox(height: 2),
                          Text(
                            'Muscle is built while you recover. Leave a day '
                            'between sessions.',
                            style: FType.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRegenerate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showFSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          FSpace.gutter,
          0,
          FSpace.gutter,
          FSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Build a new plan?', style: FType.h2),
            const SizedBox(height: FSpace.sm),
            const Text(
              'Same answers, different exercises. Your training history and '
              'logged weights are kept.',
              style: FType.small,
            ),
            const SizedBox(height: FSpace.xl),
            FButton(
              label: 'Build a new one',
              variant: FButtonVariant.primary,
              size: FButtonSize.lg,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: FSpace.sm),
            FButton(
              label: 'Keep this plan',
              variant: FButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      ref.read(planProvider.notifier).regenerate(ref.read(profileProvider));
    }
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.dayNumber,
    required this.isNext,
  });

  final PlanDay day;
  final int dayNumber;
  final bool isNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(exerciseRepoProvider);
    final working = day.workingItems;
    final exercises = <Exercise>[
      for (final item in working)
        if (repo.byId(item.exerciseId) case final e?) e,
    ];
    final bodyParts = {for (final e in exercises) e.bodyPart};

    return FCard(
      padding: const EdgeInsets.all(FSpace.lg),
      borderColor: isNext ? FColors.primary.withValues(alpha: 0.4) : null,
      onTap: () => Navigator.of(context).push(
        FPageRoute<void>(
          builder: (_) => DayScreen(day: day, dayNumber: dayNumber),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isNext ? FColors.primary : FColors.muted,
                  borderRadius: FRadius.rSm,
                  border: Border.all(
                    color: isNext ? FColors.primary : FColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: FType.num.copyWith(
                      color: isNext ? FColors.onPrimary : FColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.title, style: FType.h2),
                    const SizedBox(height: 2),
                    Text(
                      day.focus,
                      style: FType.small.copyWith(color: FColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isNext) const FTag(label: 'Next up', tone: FColors.primary),
            ],
          ),

          const SizedBox(height: FSpace.lg),

          // A row of thumbnails is a faster read than a list of names -- you
          // recognise the movement before you finish reading its title.
          SizedBox(
            height: 44,
            child: Row(
              children: [
                for (var i = 0; i < exercises.length && i < 6; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ExerciseThumb(
                      exercise: exercises[i],
                      size: 44,
                      radius: FRadius.sm,
                    ),
                  ),
                if (exercises.length > 6)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: FColors.muted,
                      borderRadius: FRadius.rSm,
                      border: Border.all(color: FColors.border),
                    ),
                    child: Center(
                      child: Text(
                        '+${exercises.length - 6}',
                        style: FType.num.copyWith(color: FColors.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: FSpace.lg),

          Row(
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final part in bodyParts.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: bodyPartColor(part),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: FSpace.md),
              Text(
                '${working.length} exercises · ${day.estimatedMinutes} min',
                style: FType.caption.copyWith(color: FColors.textFaint),
              ),
              const Spacer(),
              if (isNext)
                FButton(
                  label: 'Start',
                  variant: FButtonVariant.primary,
                  size: FButtonSize.sm,
                  icon: const FIcon(FIcons.play),
                  onPressed: ref.watch(sessionProvider) != null
                      ? null
                      : () {
                          ref.read(sessionProvider.notifier).start(day);
                          Navigator.of(context).push(
                            FPageRoute<void>(
                              fullscreen: true,
                              builder: (_) => const SessionScreen(),
                            ),
                          );
                        },
                )
              else
                const FIcon(
                  FIcons.chevronRight,
                  size: 16,
                  color: FColors.textFaint,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
