import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/exercise.dart';
import '../../../state/home_workout_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../root_screen.dart';
import '../settings/settings_screen.dart';
import 'focus_screen.dart';

/// Training at home.
///
/// The library answers "what exercises exist". This answers a narrower and far
/// more useful question: what can I do on this floor, right now, with whatever
/// is in the room. Two decisions carry the page -- what kit you have, and what
/// you want to work -- and they are the only two things on it.
class HomeWorkoutScreen extends ConsumerWidget {
  const HomeWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = ref.watch(homePoolProvider);
    final counts = ref.watch(homeFocusCountsProvider);

    return FScreen(
      title: 'At home',
      subtitle: 'No gym. No excuses about the gym.',
      bottomPadding: kTabBarInset + FSpace.xxl,
      actions: [
        FIconButton(
          icon: const FIcon(FIcons.settings),
          semanticLabel: 'Settings',
          onPressed: () => Navigator.of(
            context,
          ).push(FPageRoute<void>(builder: (_) => const SettingsScreen())),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            child: FadeSlideIn(child: _KitCard(available: pool.length)),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 90),
            child: FSection(
              title: 'What are you training?',
              subtitle: 'Pick one. Everything inside works with your kit.',
              child: const SizedBox.shrink(),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: FSpace.md,
                  crossAxisSpacing: FSpace.md,
                  // A fixed height rather than a ratio: the contents of this
                  // card are the same three lines whatever the screen is, and
                  // a ratio turns a narrow phone into a clipped card.
                  mainAxisExtent: 168,
                ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final focus = HomeFocus.values[i];
              return FadeSlideIn(
                delay: staggerDelay(
                  i,
                  interval: const Duration(milliseconds: 35),
                  baseDelay: const Duration(milliseconds: 120),
                ),
                offset: 10,
                child: _FocusCard(
                  focus: focus,
                  count: counts[focus] ?? (open: 0, all: 0),
                  preview: homeFocusPreview(pool, focus, 3),
                ),
              );
            }, childCount: HomeFocus.values.length),
          ),
        ),
      ],
    );
  }
}

/// Colour identity for a focus, carried through onto its own screen so the two
/// read as the same place.
Color homeFocusTone(HomeFocus focus) => switch (focus) {
  HomeFocus.chest => FColors.partChest,
  HomeFocus.back => FColors.partBack,
  HomeFocus.shoulders => FColors.partShoulders,
  HomeFocus.arms => FColors.partArms,
  HomeFocus.core => FColors.partCore,
  HomeFocus.legs => FColors.partLegs,
  HomeFocus.conditioning => FColors.partCardio,
  HomeFocus.mobility => FColors.indigo,
};

/// What is in the room.
///
/// Sits above everything else because it changes everything else: every count
/// on this page is a count of things this kit can actually do. Toggling a chip
/// visibly moves those numbers, which is the fastest way to explain what the
/// page is doing without a sentence of help text.
class _KitCard extends ConsumerWidget {
  const _KitCard({required this.available});

  final int available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = ref.watch(homeKitProvider);
    final controller = ref.read(homeKitProvider.notifier);

    return FCard(
      padding: const EdgeInsets.all(FSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your kit', style: FType.h3),
              const Spacer(),
              // Counts up to the new total rather than snapping, so a chip tap
              // visibly *causes* the library to grow.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: available.toDouble()),
                duration: FDur.slow,
                curve: FCurve.out,
                builder: (context, v, _) => Text(
                  '${v.round()} movements',
                  style: FType.num.copyWith(color: FColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: FSpace.md),
          Wrap(
            spacing: FSpace.sm,
            runSpacing: FSpace.sm,
            children: [
              for (final gear in HomeGear.values)
                FChip(
                  label: gear.label,
                  dense: true,
                  selected: kit.contains(gear),
                  onTap: () => controller.toggle(gear),
                ),
            ],
          ),
          const SizedBox(height: FSpace.md),
          Text(
            'A floor and a wall are assumed. Tick anything else you own.',
            style: FType.caption,
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends ConsumerWidget {
  const _FocusCard({
    required this.focus,
    required this.count,
    required this.preview,
  });

  final HomeFocus focus;
  final ({int open, int all}) count;
  final List<Exercise> preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = homeFocusTone(focus);
    final locked = count.all - count.open;

    return FCard(
      padding: const EdgeInsets.all(FSpace.lg),
      onTap: () {
        // Set before pushing, not after: a screen that opens showing the last
        // focus's results for one frame and then corrects itself is a flicker
        // the user will notice every single time.
        ref.read(homeFiltersProvider.notifier).open(focus);
        Navigator.of(context).push(
          FPageRoute<void>(builder: (_) => FocusScreen(focus: focus)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: FSpace.sm),
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  focus.label,
                  style: FType.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: FSpace.xs),
          Text(
            focus.blurb,
            style: FType.caption.copyWith(height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Stills rather than a count on its own: you recognise a push-up
          // before you finish reading the word "chest". They were circles that
          // overlapped, which on a phone read as three grey specks -- the
          // figures are drawn small inside a lot of white, so they need the
          // whole square and a gap between them.
          SizedBox(
            height: 38,
            child: Row(
              children: [
                for (final exercise in preview)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ExerciseThumb(
                      exercise: exercise,
                      size: 38,
                      radius: FRadius.sm,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: FSpace.md),

          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: count.open.toDouble()),
                duration: FDur.slow,
                curve: FCurve.out,
                builder: (context, v, _) =>
                    Text('${v.round()}', style: FType.num),
              ),
              const SizedBox(width: 4),
              Text('moves', style: FType.caption),
              const Spacer(),
              // The gap between what you can do and what exists is the whole
              // argument for owning a dumbbell, so it is stated rather than
              // silently withheld. Below five it is noise, not an argument.
              if (locked >= 5)
                Semantics(
                  label: '$locked more with extra kit',
                  child: Text(
                    '+$locked',
                    style: FType.caption.copyWith(color: FColors.textFaint),
                  ),
                )
              else
                const FIcon(
                  FIcons.chevronRight,
                  size: 14,
                  color: FColors.textFaint,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
