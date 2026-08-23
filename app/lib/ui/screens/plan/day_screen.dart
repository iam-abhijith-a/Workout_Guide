import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/plan.dart';
import '../../../state/providers.dart';
import '../../../state/session_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../library/exercise_detail_screen.dart';
import '../library/library_screen.dart';
import '../session/session_screen.dart';

/// One day of the plan, in the order it will be performed.
///
/// Groups by role rather than listing flat, so the shape of a session is
/// visible: warm up, do the two lifts that matter, fill in around them, stretch.
/// That structure is the thing a beginner is meant to internalise.
class DayScreen extends ConsumerWidget {
  const DayScreen({super.key, required this.day, required this.dayNumber});

  final PlanDay day;
  final int dayNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(exerciseRepoProvider);
    final active = ref.watch(sessionProvider);

    final groups = <PlanRole, List<PlanItem>>{};
    for (final item in day.items) {
      groups.putIfAbsent(item.role, () => []).add(item);
    }

    const order = [
      PlanRole.warmup,
      PlanRole.main,
      PlanRole.secondary,
      PlanRole.accessory,
      PlanRole.cooldown,
    ];

    return FScreen(
      title: day.title,
      subtitle: '${day.focus} · ${day.estimatedMinutes} min',
      leading: FIconButton(
        icon: const FIcon(FIcons.chevronLeft),
        semanticLabel: 'Back',
        onPressed: () => Navigator.of(context).pop(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              0,
              FSpace.gutter,
              FSpace.xxl,
            ),
            child: FadeSlideIn(
              child: FButton(
                label: active != null
                    ? 'Finish your current workout first'
                    : 'Start this workout',
                variant: FButtonVariant.primary,
                size: FButtonSize.lg,
                expand: true,
                icon: active != null ? null : const FIcon(FIcons.play),
                onPressed: active != null
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
              ),
            ),
          ),
        ),

        for (final role in order)
          if (groups[role] case final items? when items.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: Duration(milliseconds: 60 + order.indexOf(role) * 50),
                child: FSection(
                  title: role.label,
                  subtitle: role.blurb,
                  tone: roleTone(role),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FSpace.gutter,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == items.length - 1 ? 0 : FSpace.sm,
                            ),
                            child: _PlanItemRow(
                              item: items[i],
                              exercise: repo.byId(items[i].exerciseId),
                              dayIndex: day.index,
                              itemIndex: day.items.indexOf(items[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),
          ],
      ],
    );
  }
}

class _PlanItemRow extends ConsumerWidget {
  const _PlanItemRow({
    required this.item,
    required this.exercise,
    required this.dayIndex,
    required this.itemIndex,
  });

  final PlanItem item;
  final Exercise? exercise;
  final int dayIndex;
  final int itemIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = exercise;
    if (e == null) return const SizedBox.shrink();

    final isPrep =
        item.role == PlanRole.warmup || item.role == PlanRole.cooldown;

    return FCard(
      padding: const EdgeInsets.all(FSpace.md),
      onTap: () => Navigator.of(context).push(
        FPageRoute<void>(
          builder: (_) => ExerciseDetailScreen(exercise: e, onSwap: null),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ExerciseThumb(exercise: e, size: 56),
              const SizedBox(width: FSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: FType.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: FSpace.sm),
                    Row(
                      children: [
                        if (!isPrep) ...[
                          Text(
                            '${item.sets} × ${item.repRange}',
                            style: FType.num.copyWith(color: FColors.primary),
                          ),
                          const SizedBox(width: FSpace.md),
                          Text(
                            '${item.restSeconds}s rest',
                            style: FType.caption.copyWith(
                              color: FColors.textFaint,
                            ),
                          ),
                        ] else
                          Text(
                            item.role == PlanRole.warmup
                                ? '5 minutes'
                                : '30 seconds',
                            style: FType.num.copyWith(color: FColors.textMuted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DifficultyPips(level: e.difficulty),
                  const SizedBox(height: FSpace.sm),
                  PressFx(
                    onTap: () => _swap(context, ref, e),
                    scale: 0.85,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: FIcon(
                        FIcons.swap,
                        size: 15,
                        color: FColors.textFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.note != null) ...[
            const SizedBox(height: FSpace.sm),
            Row(
              children: [
                const FIcon(FIcons.info, size: 12, color: FColors.textFaint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.note!,
                    style: FType.caption.copyWith(color: FColors.textFaint),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _swap(
    BuildContext context,
    WidgetRef ref,
    Exercise current,
  ) async {
    final generator = ref.read(planGeneratorProvider);
    final profile = ref.read(profileProvider);
    final options = generator.alternativesFor(current, profile, limit: 10);

    final picked = await showFSheet<Exercise>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FSheetHeader(
            title: 'Swap exercise',
            subtitle: 'Same movement pattern, so your week stays balanced.',
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FSpace.gutter,
                0,
                FSpace.gutter,
                FSpace.lg,
              ),
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: FSpace.sm),
              itemBuilder: (context, i) => FCard(
                padding: const EdgeInsets.all(FSpace.md),
                onTap: () => Navigator.of(context).pop(options[i]),
                child: Row(
                  children: [
                    ExerciseThumb(exercise: options[i], size: 52),
                    const SizedBox(width: FSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            options[i].name,
                            style: FType.h3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            options[i].equipment,
                            style: FType.caption.copyWith(
                              color: FColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DifficultyPips(level: options[i].difficulty),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (picked != null) {
      ref.read(planProvider.notifier).swapExercise(dayIndex, itemIndex, picked);
    }
  }
}
