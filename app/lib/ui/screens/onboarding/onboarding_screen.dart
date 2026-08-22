import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/profile.dart';
import '../../../state/providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/media.dart';
import '../root_screen.dart';
import 'building_plan.dart';
import 'steps.dart';

/// Onboarding.
///
/// One question per screen, each with a single supporting line. The individual
/// questions live in `steps.dart`; this file owns only the flow -- progress,
/// direction, and what the answers turn into.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _forward = true;

  // Held locally rather than written straight to the profile, so backing out of
  // onboarding halfway does not leave a half-configured user behind.
  Goal _goal = Goal.health;
  Experience _experience = Experience.never;
  int _days = 3;
  Set<EquipClass> _equipment = {EquipClass.bodyweight};

  static const _steps = 5;

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == _steps - 1) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _forward = true;
      _step++;
    });
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _forward = false;
      _step--;
    });
  }

  void _finish() {
    ref
        .read(profileProvider.notifier)
        .update(
          (p) => p.copyWith(
            goal: _goal,
            experience: _experience,
            daysPerWeek: _days,
            equipment: _equipment,
            onboarded: true,
            createdAt: DateTime.now(),
          ),
        );

    // Built here, from a tap handler, rather than inside the next screen's
    // initState -- Riverpod forbids writing to a provider during a build.
    ref.read(planProvider.notifier).build(ref.read(profileProvider));

    Navigator.of(context).pushReplacement(
      FFadeRoute<void>(
        builder: (_) => BuildingPlanScreen(next: (_) => const RootScreen()),
      ),
    );
  }

  /// Whether the current step has enough to move on. Only equipment can
  /// genuinely block -- a plan with no available kit is not a plan.
  bool get _canAdvance => switch (_step) {
    4 => _equipment.isNotEmpty,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FBackdrop(
      child: Column(
        children: [
          // -- Progress header ------------------------------------------------
          // Hidden entirely on the welcome screen: showing "1 of 6" before
          // someone has agreed to anything frames the app as a form to fill in.
          SizedBox(
            // Must account for the status bar too, or the row inside is clipped
            // to nothing and the whole header silently disappears.
            height: topInset + 36 + FSpace.md * 2,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                FSpace.gutter,
                topInset + FSpace.md,
                FSpace.gutter,
                FSpace.md,
              ),
              child: AnimatedOpacity(
                opacity: _step == 0 ? 0 : 1,
                duration: FDur.base,
                child: IgnorePointer(
                  ignoring: _step == 0,
                  child: Row(
                    children: [
                      FIconButton(
                        icon: const FIcon(FIcons.chevronLeft),
                        onPressed: _back,
                        semanticLabel: 'Back',
                      ),
                      const SizedBox(width: FSpace.lg),
                      Expanded(
                        child: StepProgress(count: _steps, index: _step),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // -- Question -------------------------------------------------------
          Expanded(
            child: StepTransition(
              forward: _forward,
              stepKey: _step,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    FSpace.gutter,
                    0,
                    FSpace.gutter,
                    FSpace.xxl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - FSpace.xxl,
                    ),
                    child: Column(
                      // The welcome sits centred in the space it has; the
                      // questions start at the top so the title lands in the
                      // same place on every step and the eye stops moving.
                      mainAxisAlignment: _step == 0
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_buildStep()],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // -- Action ---------------------------------------------------------
          Padding(
            padding: EdgeInsets.fromLTRB(
              FSpace.gutter,
              FSpace.md,
              FSpace.gutter,
              bottomInset + FSpace.lg,
            ),
            child: FButton(
              label: switch (_step) {
                0 => 'Get started',
                4 => 'Build my plan',
                _ => 'Continue',
              },
              size: FButtonSize.lg,
              expand: true,
              onPressed: _canAdvance ? _next : null,
              trailing: const FIcon(FIcons.arrowRight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    0 => const WelcomeStep(),
    1 => GoalStep(value: _goal, onChanged: (v) => setState(() => _goal = v)),
    2 => ExperienceStep(
      value: _experience,
      onChanged: (v) => setState(() {
        _experience = v;
        // Five days is a recovery problem, not a motivation one. Quietly pull
        // an over-ambitious beginner back to something they can sustain.
        if (v == Experience.never && _days > 3) _days = 3;
      }),
    ),
    3 => DaysStep(
      value: _days,
      max: _experience == Experience.never ? 3 : 5,
      onChanged: (v) => setState(() => _days = v),
    ),
    _ => EquipmentStep(
      value: _equipment,
      onChanged: (v) => setState(() => _equipment = v),
    ),
  };
}
