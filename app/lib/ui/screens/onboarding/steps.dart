import 'package:flutter/widgets.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/profile.dart';
import '../../../data/plan/slot_templates.dart';
import '../../widgets/chips.dart';
import '../../widgets/logo.dart';
import '../../widgets/media.dart';

/// The shared shape of every onboarding question: title, one supporting line,
/// the options, and nothing else.
///
/// The one-line limit on [subtitle] is the rule that keeps this flow from
/// turning back into an essay. If a question needs a paragraph to justify
/// itself, it is the wrong question.
class StepFrame extends StatelessWidget {
  const StepFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Reserved for the one case where the app has quietly overruled the user and
  /// owes them a reason.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(child: Text(title, style: FType.h1)),
        const SizedBox(height: FSpace.sm),
        FadeSlideIn(
          delay: const Duration(milliseconds: 50),
          child: Text(subtitle, style: FType.body),
        ),
        const SizedBox(height: FSpace.xxl),
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == children.length - 1 ? 0 : FSpace.sm,
            ),
            child: FadeSlideIn(
              delay: staggerDelay(
                i,
                baseDelay: const Duration(milliseconds: 90),
              ),
              child: children[i],
            ),
          ),
        if (footnote != null) ...[
          const SizedBox(height: FSpace.lg),
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: FIcon(FIcons.info, size: 14, color: FColors.blue),
                ),
                const SizedBox(width: FSpace.sm),
                Expanded(child: Text(footnote!, style: FType.small)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The welcome screen.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  /// Three claims, one line each. A longer pitch is read by nobody deciding
  /// whether to bother with an app.
  static const _features =
      <({FIconData icon, Color tone, String title, String sub})>[
        (
          icon: FIcons.target,
          tone: FColors.violet,
          title: 'A plan, not a list',
          sub: 'Six questions, one balanced week',
        ),
        (
          icon: FIcons.dumbbell,
          tone: FColors.blue,
          title: '1,324 movements',
          sub: 'Every one demonstrated',
        ),
        (
          icon: FIcons.timer,
          tone: FColors.orange,
          title: 'Built for the gym floor',
          sub: 'Big targets, automatic rest',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(child: LogoLockup(size: 16)),
        const SizedBox(height: FSpace.x3l),
        const FadeSlideIn(
          delay: Duration(milliseconds: 80),
          child: Text('Your first 90 days\nin the gym.', style: FType.h1),
        ),
        const SizedBox(height: FSpace.md),
        const FadeSlideIn(
          delay: Duration(milliseconds: 140),
          child: Text(
            'A real training plan, built around what you can actually do.',
            style: FType.body,
          ),
        ),
        const SizedBox(height: FSpace.x3l),
        for (var i = 0; i < _features.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: FSpace.xl),
            child: FadeSlideIn(
              delay: staggerDelay(
                i,
                baseDelay: const Duration(milliseconds: 200),
                interval: const Duration(milliseconds: 60),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FIconTile(icon: _features[i].icon, tone: _features[i].tone),
                  const SizedBox(width: FSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_features[i].title, style: FType.h3),
                        const SizedBox(height: 2),
                        Text(_features[i].sub, style: FType.small),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class GoalStep extends StatelessWidget {
  const GoalStep({super.key, required this.value, required this.onChanged});

  final Goal value;
  final ValueChanged<Goal> onChanged;

  @override
  Widget build(BuildContext context) {
    return StepFrame(
      title: "What's your goal?",
      subtitle: 'Sets your reps, weight and rest.',
      children: [
        for (final goal in Goal.values)
          FChoiceRow(
            title: goal.label,
            subtitle: goal.blurb,
            selected: value == goal,
            onTap: () => onChanged(goal),
          ),
      ],
    );
  }
}

class ExperienceStep extends StatelessWidget {
  const ExperienceStep({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Experience value;
  final ValueChanged<Experience> onChanged;

  @override
  Widget build(BuildContext context) {
    return StepFrame(
      title: 'How much have you trained?',
      subtitle: 'Nothing is unlocked by picking a higher one.',
      children: [
        for (final experience in Experience.values)
          FChoiceRow(
            title: experience.label,
            subtitle: experience.blurb,
            selected: value == experience,
            onTap: () => onChanged(experience),
          ),
      ],
    );
  }
}

class DaysStep extends StatelessWidget {
  const DaysStep({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return StepFrame(
      title: 'How many days a week?',
      subtitle: 'Pick the number you will hit on a bad week.',
      // Only surfaced when the app has capped the choice, which is the one
      // moment it owes an explanation.
      footnote: max == 3
          ? 'Four and five-day plans open up once you have some training behind you.'
          : null,
      children: [
        Row(
          children: [
            for (var d = 2; d <= 5; d++) ...[
              Expanded(
                child: _DayOption(
                  days: d,
                  selected: value == d,
                  enabled: d <= max,
                  onTap: () => onChanged(d),
                ),
              ),
              if (d != 5) const SizedBox(width: FSpace.sm),
            ],
          ],
        ),
        const SizedBox(height: FSpace.lg),
        _WeekPreview(days: value),
      ],
    );
  }
}

/// The week the current answer produces.
///
/// Turns an abstract number into the actual sessions it buys, so the choice is
/// made against something concrete rather than a guess -- and it fills a screen
/// that would otherwise be one row of buttons above a void.
class _WeekPreview extends StatelessWidget {
  const _WeekPreview({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final split = splitFor(days);
    final identity = splitIdentity(days);

    return AnimatedSize(
      duration: FDur.base,
      curve: FCurve.out,
      alignment: Alignment.topCenter,
      child: Container(
        key: ValueKey(days),
        padding: const EdgeInsets.all(FSpace.lg),
        decoration: BoxDecoration(
          color: FColors.muted,
          borderRadius: FRadius.rLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(identity.name, style: FType.h3),
            const SizedBox(height: FSpace.md),
            for (var i = 0; i < split.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == split.length - 1 ? 0 : FSpace.sm,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text('${i + 1}', style: FType.caption),
                    ),
                    Expanded(child: Text(split[i].title, style: FType.body)),
                    Text(split[i].focus, style: FType.caption),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayOption extends StatelessWidget {
  const _DayOption({
    required this.days,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int days;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressFx(
      onTap: enabled ? onTap : null,
      scale: 0.94,
      child: AnimatedContainer(
        duration: FDur.fast,
        curve: FCurve.out,
        height: 68,
        decoration: BoxDecoration(
          color: selected ? FColors.primary : FColors.surface,
          borderRadius: FRadius.rLg,
          border: Border.all(
            color: selected ? FColors.primary : FColors.border,
          ),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: FDur.fast,
                style: FType.numLarge.copyWith(
                  color: selected ? FColors.onPrimary : FColors.text,
                ),
                child: Text('$days'),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: FDur.fast,
                style: FType.caption.copyWith(
                  color: selected ? FColors.onPrimary : FColors.textMuted,
                ),
                child: const Text('days'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EquipmentStep extends StatelessWidget {
  const EquipmentStep({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Set<EquipClass> value;
  final ValueChanged<Set<EquipClass>> onChanged;

  /// Ordered by how commonly people have access. `other` is deliberately absent:
  /// nobody's answer to "what do you have" is "a tyre".
  static const _offered = [
    EquipClass.bodyweight,
    EquipClass.dumbbell,
    EquipClass.machine,
    EquipClass.cable,
    EquipClass.barbell,
    EquipClass.band,
    EquipClass.kettlebell,
    EquipClass.ball,
    EquipClass.cardioMachine,
  ];

  @override
  Widget build(BuildContext context) {
    return StepFrame(
      title: 'What can you get to?',
      subtitle: 'Your plan only ever uses these.',
      children: [
        // One tap for "I have a normal gym membership" -- which is what most
        // people mean, and would otherwise be assembled from six separate chips.
        _GymPreset(
          onTap: () => onChanged({
            EquipClass.bodyweight,
            EquipClass.dumbbell,
            EquipClass.machine,
            EquipClass.cable,
            EquipClass.barbell,
            EquipClass.cardioMachine,
          }),
        ),
        const SizedBox(height: FSpace.xs),
        Wrap(
          spacing: FSpace.sm,
          runSpacing: FSpace.sm,
          children: [
            for (final equipment in _offered)
              FChip(
                label: equipment.label,
                selected: value.contains(equipment),
                onTap: () {
                  final next = {...value};
                  if (!next.remove(equipment)) next.add(equipment);
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _GymPreset extends StatelessWidget {
  const _GymPreset({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressFx(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(FSpace.md),
        decoration: BoxDecoration(
          color: FColors.wash(FColors.blue),
          borderRadius: FRadius.rLg,
          border: Border.all(color: FColors.washBorder(FColors.blue)),
        ),
        child: Row(
          children: [
            const FIcon(FIcons.sparkle, size: 16, color: FColors.blue),
            const SizedBox(width: FSpace.md),
            Expanded(
              child: Text(
                'I have a full gym membership',
                style: FType.label.copyWith(color: FColors.blue),
              ),
            ),
            const FIcon(FIcons.arrowRight, size: 14, color: FColors.blue),
          ],
        ),
      ),
    );
  }
}
