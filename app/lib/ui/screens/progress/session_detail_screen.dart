import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/session.dart';
import '../../../state/providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/indicators.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';

/// A past workout, set by set.
///
/// Exists so "what did I lift last time?" has an answer. That question is the
/// entire basis of progressive overload, and without a record the answer is
/// always a guess.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final date = session.startedAt;

    return FScreen(
      title: session.dayTitle,
      subtitle:
          '${date.day}/${date.month}/${date.year} · '
          '${session.duration.inMinutes} minutes',
      leading: FIconButton(
        icon: const FIcon(FIcons.chevronLeft),
        semanticLabel: 'Back',
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        FIconButton(
          icon: const FIcon(FIcons.trash),
          tone: FColors.rose,
          semanticLabel: 'Delete this session',
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
      slivers: [
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
                        label: 'Sets',
                        value: '${session.totalSetsDone}',
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Volume',
                        value: session.totalVolume.round().toString(),
                        suffix: profile.units.suffix,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Minutes',
                        value: '${session.duration.inMinutes}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          sliver: SliverList.separated(
            itemCount: session.exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: FSpace.sm),
            itemBuilder: (context, i) => FadeSlideIn(
              delay: staggerDelay(i),
              child: _LoggedExercise(
                log: session.exercises[i],
                units: profile.units,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
            Text('Delete this session?', style: FType.h2),
            const SizedBox(height: FSpace.sm),
            const Text(
              'It will be removed from your history and your totals. This '
              'cannot be undone.',
              style: FType.small,
            ),
            const SizedBox(height: FSpace.xl),
            FButton(
              label: 'Delete',
              variant: FButtonVariant.destructive,
              size: FButtonSize.lg,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: FSpace.sm),
            FButton(
              label: 'Keep it',
              variant: FButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(historyProvider.notifier).remove(session.id);
      Navigator.of(context).pop();
    }
  }
}

class _LoggedExercise extends StatelessWidget {
  const _LoggedExercise({required this.log, required this.units});

  final ExerciseLog log;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final done = log.sets.where((s) => s.done).toList();
    if (done.isEmpty && !log.skipped) return const SizedBox.shrink();

    return FCard(
      padding: const EdgeInsets.all(FSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(log.name, style: FType.h3)),
              if (log.skipped)
                const FTag(label: 'Skipped')
              else
                FTag(
                  label: log.role.label,
                  tone: log.role == PlanRole.main
                      ? FColors.primary
                      : FColors.textMuted,
                ),
            ],
          ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: FSpace.md),
            Wrap(
              spacing: FSpace.sm,
              runSpacing: FSpace.sm,
              children: [
                for (var i = 0; i < done.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FColors.muted,
                      borderRadius: FRadius.rSm,
                      border: Border.all(color: FColors.border),
                    ),
                    child: Text(
                      (done[i].weight ?? 0) > 0
                          ? '${done[i].reps ?? done[i].targetReps} × '
                                '${_trim(done[i].weight!)}${units.suffix}'
                          : '${done[i].reps ?? done[i].targetReps} reps',
                      style: FType.num.copyWith(color: FColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
