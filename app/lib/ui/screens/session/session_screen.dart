import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/coaching.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/session.dart';
import '../../../state/providers.dart';
import '../../../state/session_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/indicators.dart';
import '../../widgets/inputs.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../library/exercise_detail_screen.dart';
import '../library/library_screen.dart';
import 'rest_timer.dart';
import 'summary_screen.dart';

/// The workout itself.
///
/// Designed for a phone propped against a rack by someone out of breath: one
/// exercise fills the screen, set rows are 56px tall, the weight and rep
/// controls are thumb-sized, and completing a set is a single tap that also
/// starts the rest timer. Nothing here needs two hands or careful aim.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // A screen that sleeps between sets is the single most annoying thing a
    // workout app can do, so the display is held on for the whole session.
    WakelockPlus.enable();
    // Reopening a session lands on the exercise you were actually on, not
    // back at the top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = ref.read(activeExerciseIndexProvider);
      if (mounted && _pageController.hasClients && index > 0) {
        _pageController.jumpToPage(index);
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmFinish(WorkoutSession session) async {
    final incomplete = session.exercises
        .where((e) => !e.isComplete && !e.skipped)
        .length;

    final confirmed = await showFSheet<bool>(
      context: context,
      builder: (context) =>
          _FinishSheet(session: session, incomplete: incomplete),
    );

    if (confirmed != true || !mounted) return;

    final finished = ref.read(sessionProvider.notifier).finish();
    if (finished == null || !mounted) return;

    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(
      FPageRoute<void>(
        fullscreen: true,
        builder: (_) => SummaryScreen(session: finished),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final rest = ref.watch(restTimerProvider);

    // Finishing the last set of an exercise carries you to the next one. Doing
    // this from a listener rather than during build means it never fights a
    // swipe the user is in the middle of.
    ref.listen<int>(activeExerciseIndexProvider, (previous, next) {
      if (previous == null || previous == next) return;
      if (!_pageController.hasClients) return;
      if (_pageController.page?.round() == next) return;
      _pageController.animateToPage(
        next,
        duration: FDur.slow,
        curve: FCurve.out,
      );
    });

    // The session ending is what pops this screen; if it is already gone the
    // route is on its way out and there is nothing to draw.
    if (session == null) return const FBackdrop(child: SizedBox.expand());

    final activeIndex = ref.watch(activeExerciseIndexProvider);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FBackdrop(
      child: Stack(
        children: [
          Column(
            children: [
              // -- Header -----------------------------------------------------
              Padding(
                padding: EdgeInsets.fromLTRB(
                  FSpace.gutter,
                  topInset + FSpace.md,
                  FSpace.gutter,
                  FSpace.md,
                ),
                child: Row(
                  children: [
                    FIconButton(
                      icon: const FIcon(FIcons.chevronDown),
                      semanticLabel: 'Minimise workout',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: FSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.dayTitle,
                            style: FType.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          _ElapsedTime(startedAt: session.startedAt),
                        ],
                      ),
                    ),
                    FButton(
                      label: 'Finish',
                      variant: FButtonVariant.secondary,
                      size: FButtonSize.sm,
                      onPressed: () => _confirmFinish(session),
                    ),
                  ],
                ),
              ),

              // -- Overall progress --------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
                child: FProgressBar(progress: session.progress, height: 3),
              ),

              // -- Exercise pager ----------------------------------------------
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: session.exercises.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    ref.read(sessionProvider.notifier).goTo(i);
                  },
                  itemBuilder: (context, i) => _ExercisePage(
                    log: session.exercises[i],
                    exerciseIndex: i,
                    total: session.exercises.length,
                  ),
                ),
              ),

              // -- Exercise strip ----------------------------------------------
              _ExerciseStrip(
                session: session,
                activeIndex: activeIndex,
                onTap: (i) {
                  ref.read(sessionProvider.notifier).goTo(i);
                  _pageController.animateToPage(
                    i,
                    duration: FDur.slow,
                    curve: FCurve.out,
                  );
                },
              ),
              SizedBox(height: bottomInset + FSpace.md),
            ],
          ),

          // -- Rest timer ------------------------------------------------------
          // Overlaid rather than inline: rest is a modal state, and the number
          // needs to be readable from a few feet away.
          if (rest.total > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RestTimerPanel(state: rest),
            ),
        ],
      ),
    );
  }
}

/// One exercise: the demonstration, the prescription, and its sets.
class _ExercisePage extends ConsumerWidget {
  const _ExercisePage({
    required this.log,
    required this.exerciseIndex,
    required this.total,
  });

  final ExerciseLog log;
  final int exerciseIndex;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(exerciseRepoProvider);
    final exercise = repo.byId(log.exerciseId);
    final profile = ref.watch(profileProvider);
    final controller = ref.read(sessionProvider.notifier);

    if (exercise == null) {
      return const FEmptyState(
        title: 'Exercise unavailable',
        message: 'This movement is no longer in the library.',
      );
    }

    final isPrep = log.role == PlanRole.warmup || log.role == PlanRole.cooldown;

    return ListView(
      physics: const BouncingScrollPhysics(),
      // Clears the exercise strip pinned at the bottom of the screen, which
      // was slicing the last card in half.
      padding: const EdgeInsets.fromLTRB(
        FSpace.gutter,
        FSpace.lg,
        FSpace.gutter,
        FSpace.x3l,
      ),
      children: [
        Row(
          children: [
            FTag(label: log.role.label, tone: roleTone(log.role)),
            const Spacer(),
            Text(
              '${exerciseIndex + 1} of $total',
              style: FType.caption.copyWith(color: FColors.textFaint),
            ),
          ],
        ),
        const SizedBox(height: FSpace.md),

        Text(exercise.name, style: FType.h1),
        const SizedBox(height: FSpace.lg),

        ExerciseAnimation(exercise: exercise, height: 176),
        const SizedBox(height: FSpace.md),

        // Form help is one tap away at all times. Someone unsure mid-set will
        // not go hunting through a library for it.
        Row(
          children: [
            Expanded(
              child: FButton(
                label: 'How to do it',
                variant: FButtonVariant.secondary,
                size: FButtonSize.sm,
                icon: const FIcon(FIcons.info),
                onPressed: () => Navigator.of(context).push(
                  FPageRoute<void>(
                    builder: (_) => ExerciseDetailScreen(exercise: exercise),
                  ),
                ),
              ),
            ),
            const SizedBox(width: FSpace.sm),
            Expanded(
              child: FButton(
                label: 'Swap',
                variant: FButtonVariant.secondary,
                size: FButtonSize.sm,
                icon: const FIcon(FIcons.swap),
                onPressed: () => _showSwapSheet(context, ref, exercise),
              ),
            ),
          ],
        ),

        const SizedBox(height: FSpace.xl),

        if (isPrep)
          _PrepCard(
            log: log,
            exerciseIndex: exerciseIndex,
            note: log.role == PlanRole.warmup
                ? 'Five minutes, easy pace.'
                : 'Hold for 30 seconds each side.',
          )
        else ...[
          // -- Sets -----------------------------------------------------------
          Row(
            children: [
              Text('Sets', style: FType.caption),
              const Spacer(),
              Text(
                'Rest ${log.restSeconds}s between sets',
                style: FType.caption.copyWith(color: FColors.textFaint),
              ),
            ],
          ),
          const SizedBox(height: FSpace.md),

          for (var i = 0; i < log.sets.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: FSpace.sm),
              child: SetRow(
                index: i,
                set: log.sets[i],
                units: profile.units,
                unilateral: exercise.unilateral,
                onToggle: () {
                  if (log.sets[i].done) {
                    controller.uncompleteSet(exerciseIndex, i);
                  } else {
                    controller.completeSet(exerciseIndex, i);
                  }
                },
                onWeightChanged: (w) =>
                    controller.updateSet(exerciseIndex, i, weight: w),
                onRepsChanged: (r) =>
                    controller.updateSet(exerciseIndex, i, reps: r),
              ),
            ),

          const SizedBox(height: FSpace.sm),
          Row(
            children: [
              Expanded(
                child: FButton(
                  label: 'Add set',
                  variant: FButtonVariant.ghost,
                  size: FButtonSize.sm,
                  icon: const FIcon(FIcons.plus),
                  onPressed: () => controller.addSet(exerciseIndex),
                ),
              ),
              if (log.sets.length > 1)
                Expanded(
                  child: FButton(
                    label: 'Remove set',
                    variant: FButtonVariant.ghost,
                    size: FButtonSize.sm,
                    icon: const FIcon(FIcons.minus),
                    onPressed: () => controller.removeSet(exerciseIndex),
                  ),
                ),
            ],
          ),

          const SizedBox(height: FSpace.lg),

          // A cue from the coaching notes, right where the work happens.
          _CueStrip(exercise: exercise),
        ],

        const SizedBox(height: FSpace.xl),
        FButton(
          label: log.skipped ? 'Put this back in' : 'Skip this exercise',
          variant: FButtonVariant.ghost,
          size: FButtonSize.sm,
          expand: true,
          icon: const FIcon(FIcons.skip),
          onPressed: () => controller.skipExercise(exerciseIndex),
        ),
      ],
    );
  }

  Future<void> _showSwapSheet(
    BuildContext context,
    WidgetRef ref,
    Exercise current,
  ) async {
    final generator = ref.read(planGeneratorProvider);
    final profile = ref.read(profileProvider);
    final options = generator.alternativesFor(current, profile, limit: 10);

    final picked = await showFSheet<Exercise>(
      context: context,
      builder: (context) => _SwapSheet(current: current, options: options),
    );

    if (picked != null) {
      ref.read(sessionProvider.notifier).swapExercise(exerciseIndex, picked);
    }
  }
}

/// A set row.
///
/// Two stacked bands rather than one wide one: the header is the tap target for
/// "done", and the two steppers get a full half-width each underneath. Trying to
/// fit a label and two steppers on one line overflowed on a normal phone and
/// left 42px touch targets, which is not usable with sweaty hands.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.units,
    required this.unilateral,
    required this.onToggle,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  final int index;
  final SetLog set;
  final Units units;
  final bool unilateral;
  final VoidCallback onToggle;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;

  @override
  Widget build(BuildContext context) {
    final done = set.done;
    return AnimatedContainer(
      duration: FDur.base,
      curve: FCurve.out,
      padding: const EdgeInsets.all(FSpace.md),
      decoration: BoxDecoration(
        color: done ? FColors.wash(FColors.emerald) : FColors.surface,
        borderRadius: FRadius.rLg,
        border: Border.all(
          color: done ? FColors.washBorder(FColors.emerald) : FColors.border,
        ),
      ),
      child: Column(
        children: [
          PressFx(
            onTap: onToggle,
            haptic: false, // the controller fires a heavier one on completion
            scale: 0.99,
            child: Row(
              children: [
                AnimatedCheck(checked: done, size: 24, fill: FColors.emerald),
                const SizedBox(width: FSpace.md),
                Text(
                  'Set ${index + 1}',
                  style: FType.h3.copyWith(
                    color: done ? FColors.emerald : FColors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  unilateral
                      ? '${set.targetReps} per side'
                      : 'Target ${set.targetReps}',
                  style: FType.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: FSpace.md),
          Row(
            children: [
              Expanded(
                child: NumberStepper(
                  value: set.weight ?? 0,
                  onChanged: onWeightChanged,
                  step: units == Units.metric ? 2.5 : 5,
                  max: 500,
                  decimals: 1,
                  suffix: units.suffix,
                ),
              ),
              const SizedBox(width: FSpace.sm),
              Expanded(
                child: NumberStepper(
                  value: (set.reps ?? set.targetReps).toDouble(),
                  onChanged: (v) => onRepsChanged(v.round()),
                  min: 1,
                  max: 100,
                  suffix: 'reps',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warm-ups and stretches have no weight and no reps -- one tap is the whole
/// interaction.
class _PrepCard extends ConsumerWidget {
  const _PrepCard({
    required this.log,
    required this.exerciseIndex,
    required this.note,
  });

  final ExerciseLog log;
  final int exerciseIndex;
  final String note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = log.sets.isNotEmpty && log.sets.first.done;
    final controller = ref.read(sessionProvider.notifier);

    return FCard(
      color: done ? FColors.wash(FColors.emerald) : FColors.surface,
      borderColor: done ? FColors.washBorder(FColors.emerald) : null,
      padding: const EdgeInsets.all(FSpace.lg),
      onTap: () => done
          ? controller.uncompleteSet(exerciseIndex, 0)
          : controller.completeSet(exerciseIndex, 0),
      child: Row(
        children: [
          AnimatedCheck(checked: done, size: 24, fill: FColors.emerald),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Done' : 'Mark as done',
                  style: FType.h3.copyWith(
                    color: done ? FColors.emerald : FColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: FType.small.copyWith(color: FColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One coaching cue, rotating between the available ones so the same line does
/// not go stale over a training block.
class _CueStrip extends StatelessWidget {
  const _CueStrip({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final cues = coachingFor(exercise.pattern).cues;
    if (cues.isEmpty) return const SizedBox.shrink();
    // Keyed off the exercise id so it is stable for the whole session rather
    // than changing on every rebuild.
    final cue = cues[exercise.id.hashCode.abs() % cues.length];

    return Container(
      padding: const EdgeInsets.all(FSpace.md),
      decoration: BoxDecoration(
        color: FColors.wash(FColors.violet),
        borderRadius: FRadius.rMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: FIcon(FIcons.target, size: 14, color: FColors.violet),
          ),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Text(
              cue,
              style: FType.small.copyWith(color: FColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The horizontal exercise strip.
///
/// Doubles as a progress readout and a jump target: at a glance you can see how
/// many are left, and reach any of them in one tap.
class _ExerciseStrip extends StatelessWidget {
  const _ExerciseStrip({
    required this.session,
    required this.activeIndex,
    required this.onTap,
  });

  final WorkoutSession session;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
        itemCount: session.exercises.length,
        separatorBuilder: (_, __) => const SizedBox(width: FSpace.sm),
        itemBuilder: (context, i) {
          final log = session.exercises[i];
          final active = i == activeIndex;
          final complete = log.isComplete;

          return PressFx(
            onTap: () => onTap(i),
            scale: 0.92,
            child: AnimatedContainer(
              duration: FDur.base,
              curve: FCurve.out,
              width: 44,
              decoration: BoxDecoration(
                color: complete ? FColors.emerald : FColors.surface,
                borderRadius: FRadius.rMd,
                border: Border.all(
                  color: complete
                      ? FColors.emerald
                      : (active ? FColors.primary : FColors.border),
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: log.skipped
                    ? const FIcon(
                        FIcons.skip,
                        size: 13,
                        color: FColors.textFaint,
                      )
                    : complete
                    ? const FIcon(
                        FIcons.check,
                        size: 15,
                        color: FColors.onPrimary,
                      )
                    : Text(
                        '${i + 1}',
                        style: FType.num.copyWith(
                          color: active ? FColors.text : FColors.textMuted,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ticks the elapsed time.
///
/// Its own widget with its own timer so a once-a-second rebuild does not drag
/// the whole workout screen with it.
class _ElapsedTime extends StatefulWidget {
  const _ElapsedTime({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<_ElapsedTime> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} elapsed',
      style: FType.caption.copyWith(color: FColors.textFaint),
    );
  }
}

class _SwapSheet extends StatelessWidget {
  const _SwapSheet({required this.current, required this.options});

  final Exercise current;
  final List<Exercise> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FSheetHeader(
          title: 'Swap exercise',
          subtitle: 'Same movement pattern, so your session stays balanced.',
        ),
        Flexible(
          child: options.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(FSpace.x3l),
                  child: FEmptyState(
                    title: 'No alternatives',
                    message: 'Nothing else trains this pattern at your level.',
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    FSpace.gutter,
                    0,
                    FSpace.gutter,
                    FSpace.lg,
                  ),
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: FSpace.sm),
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
                                _titleCase(options[i].equipment),
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
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _FinishSheet extends StatelessWidget {
  const _FinishSheet({required this.session, required this.incomplete});

  final WorkoutSession session;
  final int incomplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(
            incomplete == 0 ? 'Finish workout?' : 'Finish early?',
            style: FType.h2,
          ),
          const SizedBox(height: FSpace.sm),
          Text(
            incomplete == 0
                ? 'Everything is logged.'
                : '$incomplete exercise${incomplete == 1 ? '' : 's'} left. '
                      'Whatever you logged is kept.',
            style: FType.small,
          ),
          const SizedBox(height: FSpace.xl),
          FButton(
            label: 'Finish and save',
            variant: FButtonVariant.primary,
            size: FButtonSize.lg,
            expand: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: FSpace.sm),
          FButton(
            label: 'Keep going',
            variant: FButtonVariant.ghost,
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
