import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/muscle_map.dart';
import '../../../data/models/exercise.dart';
import '../../../state/library_controller.dart';
import '../../../state/providers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import 'exercise_detail_screen.dart';
import 'library_screen.dart';

/// The full filter surface.
///
/// Ordered by how often it is actually used, not by how the data is shaped:
/// difficulty first, because "is this safe for me" is the beginner's real
/// question; then equipment; then the movement pattern and specific muscle for
/// people who already know what they are looking for.
class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(libraryFiltersProvider);
    final controller = ref.read(libraryFiltersProvider.notifier);
    final results = ref.watch(libraryResultsProvider);
    final repo = ref.watch(exerciseRepoProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FSheetHeader(
          title: 'Filters',
          subtitle: '${thousands(results.length)} movements match',
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
                _Group(
                  title: 'Difficulty',
                  hint: 'How technical it is, not how heavy.',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      for (final level in Difficulty.values)
                        FChip(
                          label: level.label,
                          tone: difficultyTone(level),
                          selected: filters.difficulties.contains(level),
                          onTap: () => controller.toggleDifficulty(level),
                        ),
                    ],
                  ),
                ),
                _Group(
                  title: 'Equipment',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      for (final equipment in EquipClass.values)
                        FChip(
                          label: equipment.label,
                          dense: true,
                          selected: filters.equipment.contains(equipment),
                          onTap: () => controller.toggleEquipment(equipment),
                        ),
                    ],
                  ),
                ),
                _Group(
                  title: 'Movement',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      for (final pattern in _orderedPatterns)
                        FChip(
                          label: pattern.label,
                          dense: true,
                          selected: filters.patterns.contains(pattern),
                          onTap: () => controller.togglePattern(pattern),
                        ),
                    ],
                  ),
                ),
                _Group(
                  title: 'Target muscle',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      for (final target in repo.targets)
                        FChip(
                          label: _titleCase(target),
                          dense: true,
                          selected: filters.targets.contains(target),
                          onTap: () => controller.toggleTarget(target),
                        ),
                    ],
                  ),
                ),
                _Group(
                  title: 'Body part',
                  child: Wrap(
                    spacing: FSpace.sm,
                    runSpacing: FSpace.sm,
                    children: [
                      for (final part in repo.bodyParts)
                        FChip(
                          label: _titleCase(part),
                          dense: true,
                          tone: bodyPartColor(part),
                          selected: filters.bodyParts.contains(part),
                          onTap: () => controller.toggleBodyPart(part),
                        ),
                    ],
                  ),
                ),
                _Group(
                  title: 'Sort by',
                  child: FSegmented<LibrarySort>(
                    value: filters.sort,
                    onChanged: controller.setSort,
                    options: [
                      for (final sort in LibrarySort.values)
                        (value: sort, label: sort.label),
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
                'Show ${thousands(results.length)} '
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

  /// Compounds first, accessories after -- the order a session is built in.
  static const _orderedPatterns = [
    MovementPattern.squat,
    MovementPattern.hinge,
    MovementPattern.lunge,
    MovementPattern.horizontalPush,
    MovementPattern.verticalPush,
    MovementPattern.horizontalPull,
    MovementPattern.verticalPull,
    MovementPattern.core,
    MovementPattern.legIso,
    MovementPattern.armBiceps,
    MovementPattern.armTriceps,
    MovementPattern.shoulderIso,
    MovementPattern.chestIso,
    MovementPattern.backIso,
    MovementPattern.calf,
    MovementPattern.grip,
    MovementPattern.carry,
    MovementPattern.plyo,
    MovementPattern.cardio,
    MovementPattern.stretch,
  ];

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
