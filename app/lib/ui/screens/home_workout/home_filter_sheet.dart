import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../state/home_workout_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../library/exercise_detail_screen.dart' show difficultyTone, titleCase;

/// Filters for one focus.
///
/// Every option here is built from what is actually in the open focus, so no
/// tap can ever produce an empty grid: a chest page does not offer "calves",
/// and a page with nothing advanced in it does not offer "Advanced".
class HomeFilterSheet extends ConsumerWidget {
  const HomeFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(homeFiltersProvider);
    final controller = ref.read(homeFiltersProvider.notifier);
    final focusPool = ref.watch(homeFocusPoolProvider);
    final results = ref.watch(homeResultsProvider);

    final difficulties = {for (final e in focusPool) e.difficulty}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final patterns = {for (final e in focusPool) e.pattern}.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    final targets = {for (final e in focusPool) e.target}.toList()..sort();
    final kinds = {
      for (final e in focusPool)
        for (final need in GearNeed.values)
          if (need.matches(e.homeGear!)) need,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FSheetHeader(
          title: 'Filters',
          subtitle:
              '${results.length} of ${focusPool.length} '
              '${filters.focus.label.toLowerCase()} movements',
          trailing: filters.activeCount == 0
              ? null
              : FButton(
                  label: 'Reset',
                  variant: FButtonVariant.ghost,
                  size: FButtonSize.sm,
                  onPressed: controller.clearFilters,
                ),
        ),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              0,
              FSpace.gutter,
              FSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kit first: at home it is the constraint that decides whether
                // a movement is even possible, which no other facet does.
                _Group(
                  title: 'Kit needed',
                  hint: 'Only what your kit can already do is listed.',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      for (final need in GearNeed.values)
                        if (kinds.contains(need))
                          FChip(
                            label: need.label,
                            dense: true,
                            selected: filters.gear.contains(need),
                            onTap: () => controller.toggleGear(need),
                          ),
                    ],
                  ),
                ),
                if (difficulties.length > 1)
                  _Group(
                    title: 'Difficulty',
                    hint: 'How technical it is, not how heavy.',
                    child: Wrap(
                      spacing: FSpace.sm,
                      runSpacing: FSpace.sm,
                      children: [
                        for (final level in difficulties)
                          FChip(
                            label: level.label,
                            tone: difficultyTone(level),
                            selected: filters.difficulties.contains(level),
                            onTap: () => controller.toggleDifficulty(level),
                          ),
                      ],
                    ),
                  ),
                if (patterns.length > 1)
                  _Group(
                    title: 'Movement',
                    child: Wrap(
                      spacing: FSpace.sm,
                      runSpacing: FSpace.sm,
                      children: [
                        for (final pattern in patterns)
                          FChip(
                            label: pattern.label,
                            dense: true,
                            selected: filters.patterns.contains(pattern),
                            onTap: () => controller.togglePattern(pattern),
                          ),
                      ],
                    ),
                  ),
                if (targets.length > 1)
                  _Group(
                    title: 'Muscle',
                    child: Wrap(
                      spacing: FSpace.sm,
                      runSpacing: FSpace.sm,
                      children: [
                        for (final target in targets)
                          FChip(
                            label: titleCase(target),
                            dense: true,
                            selected: filters.targets.contains(target),
                            onTap: () => controller.toggleTarget(target),
                          ),
                      ],
                    ),
                  ),
                _Group(
                  title: 'Saved',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      FChip(
                        label: 'Only saved movements',
                        dense: true,
                        leading: const FIcon(FIcons.star),
                        selected: filters.onlyFavourites,
                        onTap: () => controller.setOnlyFavourites(
                          !filters.onlyFavourites,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FSpace.gutter,
            FSpace.sm,
            FSpace.gutter,
            FSpace.lg,
          ),
          child: FButton(
            label:
                'Show ${results.length} '
                'movement${results.length == 1 ? '' : 's'}',
            size: FButtonSize.lg,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
            trailing: const FIcon(FIcons.arrowRight),
          ),
        ),
      ],
    );
  }
}

/// The sort options.
///
/// A sheet of full rows rather than a segmented control: five orderings with
/// names this long would be four pixels of text each in a segment, and the
/// explanation under each one is what makes "Recommended" mean anything.
class HomeSortSheet extends ConsumerWidget {
  const HomeSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeFiltersProvider).sort;
    final controller = ref.read(homeFiltersProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FSheetHeader(title: 'Order by'),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              0,
              FSpace.gutter,
              FSpace.xxl,
            ),
            child: Column(
              children: [
                for (final sort in HomeSort.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FSpace.sm),
                    child: FChoiceRow(
                      title: sort.label,
                      subtitle: _blurb(sort),
                      selected: sort == current,
                      onTap: () {
                        controller.setSort(sort);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _blurb(HomeSort sort) => switch (sort) {
    HomeSort.recommended => 'Least kit first, then the big movements',
    HomeSort.easiest => 'Start where the technique is simplest',
    HomeSort.hardest => 'For when the easy version stopped being hard',
    HomeSort.nameAsc => 'Alphabetical, for when you know the name',
  };
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child, this.hint});

  final String title;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FType.h3),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: FType.small),
          ],
          const SizedBox(height: FSpace.md),
          child,
        ],
      ),
    );
  }
}
