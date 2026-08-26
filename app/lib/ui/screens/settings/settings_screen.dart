import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/profile.dart';
import '../../../state/providers.dart';
import '../../../state/session_controller.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/inputs.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../onboarding/onboarding_screen.dart';

/// Settings.
///
/// Everything asked during onboarding is changeable here, because the honest
/// answer to "what are you here for?" changes over a year -- and a plan you
/// cannot adjust is one you eventually abandon.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);
    final history = ref.watch(historyProvider);

    return FScreen(
      title: 'Settings',
      leading: FIconButton(
        icon: const FIcon(FIcons.chevronLeft),
        semanticLabel: 'Back',
        onPressed: () => Navigator.of(context).pop(),
      ),
      slivers: [
        // -- Training ---------------------------------------------------------
        _Group(
          title: 'Training',
          delay: 0,
          children: [
            _NavRow(
              label: 'Goal',
              value: profile.goal.label,
              onTap: () => _pickGoal(context, ref),
            ),
            _NavRow(
              label: 'Experience',
              value: profile.experience.label,
              onTap: () => _pickExperience(context, ref),
            ),
            _NavRow(
              label: 'Days per week',
              value: '${profile.daysPerWeek}',
              onTap: () => _pickDays(context, ref),
            ),
            _NavRow(
              label: 'Equipment',
              value: '${profile.equipment.length} selected',
              onTap: () => _pickEquipment(context, ref),
            ),
          ],
        ),

        // Changing any training answer invalidates the current plan, so say so
        // rather than silently leaving a plan that no longer matches.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              FSpace.md,
              FSpace.gutter,
              FSpace.xxl,
            ),
            child: FButton(
              label: 'Rebuild my plan from these answers',
              variant: FButtonVariant.secondary,
              expand: true,
              icon: const FIcon(FIcons.swap),
              onPressed: () {
                ref.read(planProvider.notifier).build(profile);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),

        // -- Preferences ------------------------------------------------------
        _Group(
          title: 'Preferences',
          delay: 60,
          children: [
            _SegmentRow(
              label: 'Units',
              child: FSegmented<Units>(
                value: profile.units,
                onChanged: (u) =>
                    controller.update((p) => p.copyWith(units: u)),
                options: [
                  for (final unit in Units.values)
                    (value: unit, label: '${unit.label} (${unit.suffix})'),
                ],
              ),
            ),
            _ToggleRow(
              label: 'Automatic rest timer',
              description: 'Starts counting the moment you log a set.',
              value: profile.restTimerEnabled,
              onChanged: (v) =>
                  controller.update((p) => p.copyWith(restTimerEnabled: v)),
            ),
            _EditableRow(
              label: 'Name',
              value: profile.name,
              hint: 'Your name',
              onChanged: (v) => controller.update((p) => p.copyWith(name: v)),
            ),
          ],
        ),

        // -- Data -------------------------------------------------------------
        _Group(
          title: 'Your data',
          delay: 120,
          children: [
            _InfoRow(label: 'Sessions logged', value: '${history.length}'),
            _InfoRow(
              label: 'Training since',
              value: profile.createdAt == null
                  ? '—'
                  : '${profile.createdAt!.day}/${profile.createdAt!.month}/'
                        '${profile.createdAt!.year}',
            ),
            _InfoRow(label: 'Stored', value: 'On this device only'),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            child: FCard(
              color: FColors.muted,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: FIcon(
                      FIcons.info,
                      size: 15,
                      color: FColors.textFaint,
                    ),
                  ),
                  const SizedBox(width: FSpace.md),
                  Expanded(
                    child: Text(
                      'Workout Guide has no account, no server and makes no network '
                      'requests. Your plan, your history and your logged weights '
                      'live on this device and nowhere else — which is also why '
                      'the whole app works with no signal.',
                      style: FType.small.copyWith(color: FColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.xxl)),

        // -- Reset ------------------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
            child: FButton(
              label: 'Start over',
              variant: FButtonVariant.destructive,
              expand: true,
              icon: const FIcon(FIcons.trash),
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: FSpace.x3l)),

        SliverToBoxAdapter(
          child: Center(
            child: Column(
              children: [
                const FIcon(
                  FIcons.dumbbell,
                  size: 22,
                  color: FColors.textFaint,
                ),
                const SizedBox(height: FSpace.md),
                Text(
                  'Workout Guide 1.0',
                  style: FType.caption.copyWith(color: FColors.textFaint),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exercise media © Gym visual — gymvisual.com',
                  style: FType.caption.copyWith(color: FColors.textFaint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickGoal(BuildContext context, WidgetRef ref) =>
      showFSheet<void>(
        context: context,
        builder: (context) => _OptionSheet(
          title: 'What are you here for?',
          subtitle: 'This sets your sets, reps and rest.',
          children: [
            for (final goal in Goal.values)
              Consumer(
                builder: (context, ref, _) => Padding(
                  padding: const EdgeInsets.only(bottom: FSpace.sm),
                  child: FChoiceRow(
                    title: goal.label,
                    subtitle: goal.explainer,
                    selected: ref.watch(profileProvider).goal == goal,
                    onTap: () {
                      ref
                          .read(profileProvider.notifier)
                          .update((p) => p.copyWith(goal: goal));
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        ),
      );

  Future<void> _pickExperience(BuildContext context, WidgetRef ref) =>
      showFSheet<void>(
        context: context,
        builder: (context) => _OptionSheet(
          title: 'How much have you trained?',
          subtitle: 'This caps how technical your plan gets.',
          children: [
            for (final experience in Experience.values)
              Consumer(
                builder: (context, ref, _) => Padding(
                  padding: const EdgeInsets.only(bottom: FSpace.sm),
                  child: FChoiceRow(
                    title: experience.label,
                    subtitle: experience.explainer,
                    selected:
                        ref.watch(profileProvider).experience == experience,
                    onTap: () {
                      ref
                          .read(profileProvider.notifier)
                          .update(
                            (p) => p.copyWith(
                              experience: experience,
                              daysPerWeek:
                                  experience == Experience.never &&
                                      p.daysPerWeek > 3
                                  ? 3
                                  : p.daysPerWeek,
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        ),
      );

  Future<void> _pickDays(
    BuildContext context,
    WidgetRef ref,
  ) => showFSheet<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final profile = ref.watch(profileProvider);
        final max = profile.experience == Experience.never ? 3 : 5;
        return _OptionSheet(
          title: 'How many days a week?',
          subtitle: max == 3
              ? 'Four and five-day plans open up once you have some training '
                    'behind you.'
              : 'Pick the number you will hit on a bad week.',
          children: [
            for (var d = 2; d <= 5; d++)
              Padding(
                padding: const EdgeInsets.only(bottom: FSpace.sm),
                child: Opacity(
                  opacity: d <= max ? 1 : 0.35,
                  child: FChoiceRow(
                    title: '$d days a week',
                    subtitle: switch (d) {
                      2 => 'Two full-body sessions',
                      3 => 'Three full-body sessions',
                      4 => 'Upper and lower, twice each',
                      _ => 'Push, pull, legs, plus upper and lower',
                    },
                    selected: profile.daysPerWeek == d,
                    onTap: () {
                      if (d > max) return;
                      ref
                          .read(profileProvider.notifier)
                          .update((p) => p.copyWith(daysPerWeek: d));
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _pickEquipment(BuildContext context, WidgetRef ref) =>
      showFSheet<void>(
        context: context,
        builder: (context) => Consumer(
          builder: (context, ref, _) {
            final profile = ref.watch(profileProvider);
            return _OptionSheet(
              title: 'What can you get to?',
              subtitle: 'Your plan only ever uses these.',
              children: [
                Wrap(
                  spacing: FSpace.sm,
                  runSpacing: FSpace.sm,
                  children: [
                    for (final equipment in EquipClass.values)
                      FChip(
                        label: equipment.label,
                        selected: profile.equipment.contains(equipment),
                        onTap: () {
                          final next = {...profile.equipment};
                          if (!next.remove(equipment)) next.add(equipment);
                          // Never let the set empty out -- a plan needs
                          // something to draw from.
                          if (next.isEmpty) return;
                          ref
                              .read(profileProvider.notifier)
                              .update((p) => p.copyWith(equipment: next));
                        },
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
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
            Text('Delete everything?', style: FType.h2),
            const SizedBox(height: FSpace.sm),
            const Text(
              'Your profile, plan, training history and saved exercises will '
              'all be erased, and you will start onboarding again. This cannot '
              'be undone.',
              style: FType.small,
            ),
            const SizedBox(height: FSpace.xl),
            FButton(
              label: 'Delete everything',
              variant: FButtonVariant.destructive,
              size: FButtonSize.lg,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: FSpace.sm),
            FButton(
              label: 'Cancel',
              variant: FButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(storageProvider).clearAll();
    if (!context.mounted) return;

    ref.read(profileProvider.notifier).reset();
    ref.read(planProvider.notifier).clear();
    ref.read(historyProvider.notifier).clear();
    ref.read(sessionProvider.notifier).discard();

    Navigator.of(context).pushAndRemoveUntil(
      FFadeRoute<void>(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }
}

// -- Row primitives -----------------------------------------------------------

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.children,
    required this.delay,
  });

  final String title;
  final List<Widget> children;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: FadeSlideIn(
        delay: Duration(milliseconds: delay),
        child: Padding(
          padding: const EdgeInsets.only(bottom: FSpace.xxl),
          child: FSection(
            title: title,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              child: FCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) Container(height: 1, color: FColors.border),
                      children[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressFx(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FSpace.lg,
          vertical: FSpace.lg,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: FType.label)),
            Text(
              value,
              style: FType.caption.copyWith(color: FColors.textMuted),
            ),
            const SizedBox(width: FSpace.sm),
            const FIcon(
              FIcons.chevronRight,
              size: 15,
              color: FColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: FSpace.lg,
      vertical: FSpace.lg,
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: FType.label)),
        Text(value, style: FType.caption.copyWith(color: FColors.textMuted)),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: FSpace.lg,
      vertical: FSpace.lg,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: FType.label),
              const SizedBox(height: 2),
              Text(
                description,
                style: FType.caption.copyWith(color: FColors.textFaint),
              ),
            ],
          ),
        ),
        const SizedBox(width: FSpace.md),
        FToggle(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: FSpace.lg,
      vertical: FSpace.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FType.label),
        const SizedBox(height: FSpace.md),
        child,
      ],
    ),
  );
}

class _EditableRow extends StatefulWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_EditableRow> createState() => _EditableRowState();
}

class _EditableRowState extends State<_EditableRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: FSpace.lg,
      vertical: FSpace.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: FType.label),
        const SizedBox(height: FSpace.md),
        FTextField(
          controller: _controller,
          hint: widget.hint,
          height: 46,
          style: FType.label,
          textCapitalization: TextCapitalization.words,
          onChanged: widget.onChanged,
        ),
      ],
    ),
  );
}

class _OptionSheet extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FSheetHeader(title: title, subtitle: subtitle),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              0,
              FSpace.gutter,
              FSpace.lg,
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
