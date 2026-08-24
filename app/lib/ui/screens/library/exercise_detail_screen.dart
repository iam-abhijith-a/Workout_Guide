import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/coaching.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/plan.dart';
import '../../../state/providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/body_map.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';

/// Everything about one movement.
///
/// The previous version stacked seven sections into one long scroll, which is
/// the fastest way to make a beginner close an app. The content now sits behind
/// three tabs -- see it, understand it, get it right -- so each view answers
/// exactly one question and nothing is read that was not asked for.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exercise, this.onSwap});

  final Exercise exercise;

  /// Supplied when opened from inside a plan or a live session, where "use a
  /// different exercise" is a real action rather than browsing.
  final VoidCallback? onSwap;

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

enum _Tab { steps, muscles, tips }

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  _Tab _tab = _Tab.steps;

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final isFavourite = ref.watch(favouritesProvider).contains(exercise.id);

    return FBackdrop(
      child: FScreen(
        title: exercise.name,
        subtitle: exercise.pattern.label,
        leading: FIconButton(
          icon: const FIcon(FIcons.chevronLeft),
          semanticLabel: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          FIconButton(
            icon: FIcon(isFavourite ? FIcons.starFilled : FIcons.star),
            tone: isFavourite ? FColors.amber : FColors.textSecondary,
            semanticLabel: isFavourite ? 'Remove from saved' : 'Save',
            onPressed: () =>
                ref.read(favouritesProvider.notifier).toggle(exercise.id),
          ),
        ],
        slivers: [
          // -- Demonstration --------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              child: FadeSlideIn(
                child: ExerciseAnimation(exercise: exercise, height: 230),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: FSpace.md)),

          // -- Facts ----------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: Wrap(
                  spacing: FSpace.sm,
                  runSpacing: FSpace.sm,
                  children: [
                    FTag(
                      label: exercise.difficulty.label,
                      tone: difficultyTone(exercise.difficulty),
                    ),
                    FTag(label: titleCase(exercise.equipment)),
                    FTag(label: titleCase(exercise.target)),
                    if (exercise.unilateral) const FTag(label: 'Per side'),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: FSpace.xl)),

          // -- Tabs -----------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: FSegmented<_Tab>(
                  value: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                  options: const [
                    (value: _Tab.steps, label: 'Steps'),
                    (value: _Tab.muscles, label: 'Muscles'),
                    (value: _Tab.tips, label: 'Tips'),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: FSpace.lg)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              child: AnimatedSize(
                duration: FDur.base,
                curve: FCurve.out,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: FDur.fast,
                  switchInCurve: FCurve.out,
                  switchOutCurve: FCurve.exit,
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: switch (_tab) {
                      _Tab.steps => _StepsTab(exercise: exercise),
                      _Tab.muscles => _MusclesTab(exercise: exercise),
                      _Tab.tips => _TipsTab(exercise: exercise),
                    },
                  ),
                ),
              ),
            ),
          ),

          if (widget.onSwap != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FSpace.gutter,
                  FSpace.xxl,
                  FSpace.gutter,
                  0,
                ),
                child: FButton(
                  label: 'Use this exercise',
                  size: FButtonSize.lg,
                  expand: true,
                  onPressed: widget.onSwap,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: FSpace.section)),

          SliverToBoxAdapter(child: _Similar(exercise: exercise)),
        ],
      ),
    );
  }
}

String titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Colour for a plan role, so a session's shape reads without labels.
Color roleTone(PlanRole role) => switch (role) {
  PlanRole.warmup => FColors.orange,
  PlanRole.main => FColors.blue,
  PlanRole.secondary => FColors.violet,
  PlanRole.accessory => FColors.teal,
  PlanRole.cooldown => FColors.emerald,
};

/// Colour for a difficulty. Green / amber / red is the one place in this app
/// where colour carries a meaning everyone already knows.
Color difficultyTone(Difficulty d) => switch (d) {
  Difficulty.beginner => FColors.emerald,
  Difficulty.intermediate => FColors.amber,
  Difficulty.advanced => FColors.rose,
};

/// The instructions, numbered on a connected timeline.
///
/// The connector matters: it makes the sequence read as one procedure rather
/// than a bag of unordered sentences.
class _StepsTab extends StatelessWidget {
  const _StepsTab({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final steps = exercise.steps;
    return FCard(
      padding: const EdgeInsets.all(FSpace.lg),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: FColors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: FType.caption),
                        ),
                      ),
                      if (i != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: FColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: FSpace.md),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 1,
                        bottom: i == steps.length - 1 ? 0 : FSpace.lg,
                      ),
                      child: Text(steps[i], style: FType.body),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MusclesTab extends StatelessWidget {
  const _MusclesTab({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final regions = regionsFor(
      target: exercise.target,
      secondary: exercise.secondary,
    );
    return FCard(
      padding: const EdgeInsets.all(FSpace.lg),
      child: Column(
        children: [
          BodyMap(
            primary: regions.primary,
            secondary: regions.secondary,
            height: 210,
          ),
          const SizedBox(height: FSpace.xl),
          MuscleLegend(target: exercise.target, secondary: exercise.secondary),
        ],
      ),
    );
  }
}

/// Cues, mistakes and setup.
///
/// Behind a tab because it is the longest content in the app, and someone
/// checking "how many reps" should never have to scroll past it.
class _TipsTab extends StatelessWidget {
  const _TipsTab({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final coaching = coachingFor(exercise.pattern);
    final equipmentTip = equipmentTips[exercise.equipClass];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FCard(
          padding: const EdgeInsets.all(FSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FIcon(FIcons.target, size: 15, color: FColors.violet),
                  const SizedBox(width: FSpace.sm),
                  Text('While you lift', style: FType.h3),
                ],
              ),
              const SizedBox(height: FSpace.md),
              for (var i = 0; i < coaching.cues.length; i++) ...[
                if (i > 0) const SizedBox(height: FSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, right: FSpace.md),
                      decoration: const BoxDecoration(
                        color: FColors.violet,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: Text(coaching.cues[i], style: FType.body)),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: FSpace.sm),

        for (final mistake in coaching.mistakes)
          Padding(
            padding: const EdgeInsets.only(bottom: FSpace.sm),
            child: FCard(
              padding: const EdgeInsets.all(FSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: FIcon(
                          FIcons.alert,
                          size: 15,
                          color: FColors.amber,
                        ),
                      ),
                      const SizedBox(width: FSpace.sm),
                      Expanded(child: Text(mistake.problem, style: FType.h3)),
                    ],
                  ),
                  const SizedBox(height: FSpace.sm),
                  Padding(
                    padding: const EdgeInsets.only(left: 23),
                    child: Text(mistake.fix, style: FType.small),
                  ),
                ],
              ),
            ),
          ),

        if (equipmentTip != null)
          FCard(
            color: FColors.wash(FColors.blue),
            borderColor: FColors.washBorder(FColors.blue),
            padding: const EdgeInsets.all(FSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: FIcon(FIcons.info, size: 15, color: FColors.blue),
                ),
                const SizedBox(width: FSpace.sm),
                Expanded(child: Text(equipmentTip, style: FType.small)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Other ways to train the same pattern.
///
/// A horizontal strip of thumbnails rather than full rows: this is a browse
/// affordance, not a decision, so it costs one band of height rather than a
/// second screenful.
class _Similar extends ConsumerWidget {
  const _Similar({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generator = ref.watch(planGeneratorProvider);
    final profile = ref.watch(profileProvider);
    final alternatives = generator.alternativesFor(exercise, profile, limit: 8);
    if (alternatives.isEmpty) return const SizedBox.shrink();

    return FSection(
      title: 'Similar movements',
      subtitle: 'Same job, different kit.',
      child: SizedBox(
        height: ExerciseTile.stripHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          itemCount: alternatives.length,
          separatorBuilder: (_, __) => const SizedBox(width: FSpace.md),
          itemBuilder: (context, i) => ExerciseTile(
            exercise: alternatives[i],
            meta: titleCase(alternatives[i].equipment),
            onTap: () => Navigator.of(context).pushReplacement(
              FPageRoute<void>(
                builder: (_) => ExerciseDetailScreen(exercise: alternatives[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
