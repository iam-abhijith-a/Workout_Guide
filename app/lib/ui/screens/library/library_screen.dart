import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/muscle_map.dart';
import '../../../data/models/exercise.dart';
import '../../../state/library_controller.dart';
import '../../../state/providers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/inputs.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../root_screen.dart';
import 'exercise_detail_screen.dart';
import 'filter_sheet.dart';

/// The exercise library.
///
/// The reference page this app grew out of put every facet in a permanent
/// sidebar, which works on a desktop and not at all on a phone. Here search is
/// always visible, the two filters people actually reach for sit inline, and the
/// long tail lives in a sheet -- so the default state is a wall of exercises
/// rather than a wall of controls.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(libraryFiltersProvider);
    final results = ref.watch(libraryResultsProvider);
    final controller = ref.read(libraryFiltersProvider.notifier);
    final repo = ref.watch(exerciseRepoProvider);

    // Unlike every other screen, the library does not use the collapsing large
    // title. Search *is* the screen: scrolling a thousand rows and then having
    // to scroll all the way back up to refine a query is the single worst thing
    // this surface could do, so the controls are fixed and only results move.
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            FSpace.gutter,
            MediaQuery.paddingOf(context).top + FSpace.xl,
            FSpace.gutter,
            FSpace.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Library', style: FType.h1),
                    const SizedBox(height: 2),
                    Text(
                      '${thousands(repo.all.length)} movements, every one '
                      'demonstrated',
                      style: FType.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // -- Search + filters -------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FSpace.gutter,
            0,
            FSpace.gutter,
            FSpace.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: FSearchField(
                  controller: _searchController,
                  hint: 'Search movements or muscles',
                  onChanged: controller.setQuery,
                ),
              ),
              const SizedBox(width: FSpace.sm),
              _FilterButton(
                count: filters.activeCount,
                onTap: () => showFSheet<void>(
                  context: context,
                  builder: (_) => const FilterSheet(),
                ),
              ),
            ],
          ),
        ),

        // -- Quick facets -----------------------------------------------------
        // Body part is how a beginner thinks ("I want to do chest today"), and
        // "what I can actually do" is the filter that turns a catalogue into a
        // usable shortlist. Everything else is one tap deeper.
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            children: [
              FChip(
                label: 'My equipment',
                dense: true,
                selected: filters.onlyMyEquipment,
                leading: const FIcon(FIcons.check),
                onTap: () =>
                    controller.setOnlyMyEquipment(!filters.onlyMyEquipment),
              ),
              const SizedBox(width: FSpace.sm),
              FChip(
                label: 'Saved',
                dense: true,
                selected: filters.onlyFavourites,
                leading: const FIcon(FIcons.star),
                onTap: () =>
                    controller.setOnlyFavourites(!filters.onlyFavourites),
              ),
              const SizedBox(width: FSpace.sm),
              Container(width: 1, height: 20, color: FColors.border),
              const SizedBox(width: FSpace.sm),
              for (final part in repo.bodyParts) ...[
                FChip(
                  label: _titleCase(part),
                  dense: true,
                  selected: filters.bodyParts.contains(part),
                  tone: bodyPartColor(part),
                  onTap: () => controller.toggleBodyPart(part),
                ),
                const SizedBox(width: FSpace.sm),
              ],
            ],
          ),
        ),

        // -- Result count -----------------------------------------------------
        // Hidden until something is filtered: an unfiltered count merely
        // repeats the subtitle two lines above it.
        if (!filters.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              FSpace.lg,
              FSpace.gutter,
              FSpace.md,
            ),
            child: Row(
              children: [
                // The count animates between values rather than snapping, so a
                // filter tap visibly *causes* the list to narrow.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: results.length.toDouble()),
                  duration: FDur.slow,
                  curve: FCurve.out,
                  builder: (context, v, _) => Text(
                    '${v.round()} result${v.round() == 1 ? '' : 's'}',
                    style: FType.caption.copyWith(color: FColors.textMuted),
                  ),
                ),
                const Spacer(),
                PressFx(
                  onTap: () {
                    _searchController.clear();
                    controller.clearAll();
                  },
                  child: Text(
                    'Clear',
                    style: FType.label.copyWith(color: FColors.blue),
                  ),
                ),
              ],
            ),
          ),

        // -- Results ----------------------------------------------------------
        Expanded(
          child: results.isEmpty
              ? FEmptyState(
                  icon: FIcons.search,
                  title: 'Nothing matches',
                  message: filters.onlyMyEquipment
                      ? 'Try turning off "My equipment".'
                      : 'Try fewer filters, or a shorter search.',
                  action: FButton(
                    label: 'Clear filters',
                    variant: FButtonVariant.secondary,
                    size: FButtonSize.sm,
                    onPressed: () {
                      _searchController.clear();
                      controller.clearAll();
                    },
                  ),
                )
              : FadeEdge(
                  // Rows dissolve into the tab bar instead of being sliced by it.
                  top: 12,
                  bottom: 28,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      FSpace.gutter,
                      0,
                      FSpace.gutter,
                      kTabBarInset + FSpace.xxl,
                    ),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: FSpace.sm),
                    itemBuilder: (context, i) => ExerciseRow(
                      exercise: results[i],
                      // Only the first screenful is staggered. Rows further down
                      // appear as the user scrolls to them, and animating those
                      // would make scrolling feel laggy rather than lively.
                      index: i < 8 ? i : null,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  static String _titleCase(String s) => titleCase(s);
}

/// 1324 -> 1,324. Four-digit counts read as a year without it.
String thousands(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return PressFx(
      onTap: onTap,
      scale: 0.93,
      child: AnimatedContainer(
        duration: FDur.fast,
        curve: FCurve.out,
        height: 46,
        padding: EdgeInsets.symmetric(horizontal: active ? 12 : 14),
        decoration: BoxDecoration(
          color: active ? FColors.wash(FColors.primary) : FColors.muted,
          borderRadius: FRadius.rLg,
          border: Border.all(
            color: active
                ? FColors.primary.withValues(alpha: 0.45)
                : FColors.border,
          ),
        ),
        child: Row(
          children: [
            FIcon(
              FIcons.filter,
              size: 17,
              color: active ? FColors.primary : FColors.textSecondary,
            ),
            // The badge grows in rather than appearing, so a filter being
            // applied has a visible consequence right where the user tapped.
            AnimatedSize(
              duration: FDur.base,
              curve: FCurve.out,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '$count',
                        style: FType.num.copyWith(color: FColors.primary),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A library row.
///
/// Shows the still frame, the name, and the three facts that decide whether this
/// is the right exercise: what it works, what it needs, and how hard it is.
/// A library row.
///
/// Deliberately compact. This list is 1,324 items long, so every pixel of row
/// height is a row the user cannot see -- and the star that used to sit on each
/// row is gone entirely: saving is a decision you make on the detail screen,
/// not something worth 1,324 repetitions of visual noise.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({super.key, required this.exercise, this.index});

  final Exercise exercise;

  /// Set for the first screenful only, to stagger them in.
  final int? index;

  @override
  Widget build(BuildContext context) {
    final row = FCard(
      padding: const EdgeInsets.all(FSpace.sm),
      radius: FRadius.lg,
      onTap: () => Navigator.of(context).push(
        FPageRoute<void>(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        ),
      ),
      child: Row(
        children: [
          ExerciseThumb(exercise: exercise, size: 52, radius: FRadius.sm),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: FType.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: bodyPartColor(exercise.bodyPart),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${titleCase(exercise.target)}  ·  '
                        '${titleCase(exercise.equipment)}',
                        style: FType.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: FSpace.md),
          DifficultyPips(level: exercise.difficulty),
          const SizedBox(width: FSpace.md),
        ],
      ),
    );

    if (index == null) return row;
    return FadeSlideIn(delay: staggerDelay(index!), offset: 8, child: row);
  }
}

/// Difficulty as three ascending bars.
///
/// A shape you can read without a legend, and it takes a fraction of the width
/// of the word "Intermediate". Ascending height carries the ordering that three
/// equal dots do not.
class DifficultyPips extends StatelessWidget {
  const DifficultyPips({super.key, required this.level});

  final Difficulty level;

  @override
  Widget build(BuildContext context) {
    final filled = level.index + 1;
    final tone = difficultyTone(level);

    return Semantics(
      label: level.label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 3,
              height: 6.0 + i * 3,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
              decoration: BoxDecoration(
                color: i < filled ? tone : FColors.border,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }
}
