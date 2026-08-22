import '../models/exercise.dart';
import '../models/plan.dart';

/// A single position in a session: "the main pushing movement", "an accessory
/// for the back of the arm".
///
/// Slots are defined by movement *pattern*, not by muscle, because that is what
/// keeps a week balanced. Fill every slot and the pushes and pulls come out even
/// on their own -- which is exactly what a beginner cannot yet do by eye.
class Slot {
  const Slot(this.patterns, this.role, {this.label});

  /// Ordered by preference. If nothing suitable exists for the first pattern
  /// (say, the user has no barbell), the next is tried before giving up.
  final List<MovementPattern> patterns;
  final PlanRole role;

  /// Overrides the pattern name in the plan view where a friendlier word helps.
  final String? label;
}

/// A named training day: its slots and how it is described to the user.
class DayTemplate {
  const DayTemplate({
    required this.title,
    required this.focus,
    required this.slots,
  });

  final String title;
  final String focus;
  final List<Slot> slots;
}

typedef _Mp = MovementPattern;

/// Full-body days. The right answer for almost everyone training two or three
/// times a week: every session hits everything, so a missed day costs less.
const _fullBodyA = DayTemplate(
  title: 'Full Body A',
  focus: 'Legs, chest and back',
  slots: [
    Slot([_Mp.squat, _Mp.lunge, _Mp.legIso], PlanRole.main),
    Slot([_Mp.horizontalPush, _Mp.chestIso], PlanRole.main),
    Slot([
      _Mp.horizontalPull,
      _Mp.verticalPull,
      _Mp.backIso,
    ], PlanRole.secondary),
    Slot([_Mp.hinge, _Mp.legIso], PlanRole.secondary),
    Slot([_Mp.shoulderIso, _Mp.verticalPush], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

const _fullBodyB = DayTemplate(
  title: 'Full Body B',
  focus: 'Hips, shoulders and back',
  slots: [
    Slot([_Mp.hinge, _Mp.legIso], PlanRole.main),
    Slot([_Mp.verticalPull, _Mp.horizontalPull, _Mp.backIso], PlanRole.main),
    Slot([_Mp.verticalPush, _Mp.horizontalPush], PlanRole.secondary),
    Slot([_Mp.lunge, _Mp.squat, _Mp.legIso], PlanRole.secondary),
    Slot([_Mp.armBiceps, _Mp.armTriceps], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

const _fullBodyC = DayTemplate(
  title: 'Full Body C',
  focus: 'Single-leg work, arms and core',
  slots: [
    Slot([_Mp.lunge, _Mp.squat, _Mp.legIso], PlanRole.main),
    Slot([_Mp.horizontalPull, _Mp.verticalPull], PlanRole.main),
    Slot([_Mp.horizontalPush, _Mp.verticalPush], PlanRole.secondary),
    Slot([_Mp.legIso, _Mp.hinge], PlanRole.secondary),
    Slot([_Mp.armTriceps, _Mp.armBiceps], PlanRole.accessory),
    Slot([_Mp.calf, _Mp.core], PlanRole.accessory),
  ],
);

/// Upper/lower. Four days a week, each half of the body twice.
const _upperA = DayTemplate(
  title: 'Upper A',
  focus: 'Chest, shoulders and arms',
  slots: [
    Slot([_Mp.horizontalPush, _Mp.chestIso], PlanRole.main),
    Slot([_Mp.horizontalPull, _Mp.backIso], PlanRole.main),
    Slot([_Mp.verticalPush, _Mp.shoulderIso], PlanRole.secondary),
    Slot([_Mp.verticalPull, _Mp.backIso], PlanRole.secondary),
    Slot([_Mp.armTriceps], PlanRole.accessory),
    Slot([_Mp.armBiceps], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

const _lowerA = DayTemplate(
  title: 'Lower A',
  focus: 'Quads, glutes and calves',
  slots: [
    Slot([_Mp.squat, _Mp.legIso], PlanRole.main),
    Slot([_Mp.hinge, _Mp.legIso], PlanRole.main),
    Slot([_Mp.lunge, _Mp.squat], PlanRole.secondary),
    Slot([_Mp.legIso], PlanRole.secondary),
    Slot([_Mp.calf], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

const _upperB = DayTemplate(
  title: 'Upper B',
  focus: 'Back, shoulders and arms',
  slots: [
    Slot([_Mp.verticalPull, _Mp.horizontalPull], PlanRole.main),
    Slot([_Mp.verticalPush, _Mp.horizontalPush], PlanRole.main),
    Slot([_Mp.horizontalPull, _Mp.backIso], PlanRole.secondary),
    Slot([_Mp.horizontalPush, _Mp.chestIso], PlanRole.secondary),
    Slot([_Mp.shoulderIso], PlanRole.accessory),
    Slot([_Mp.armBiceps], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

const _lowerB = DayTemplate(
  title: 'Lower B',
  focus: 'Hamstrings, glutes and core',
  slots: [
    Slot([_Mp.hinge, _Mp.legIso], PlanRole.main),
    Slot([_Mp.lunge, _Mp.squat], PlanRole.main),
    Slot([_Mp.squat, _Mp.legIso], PlanRole.secondary),
    Slot([_Mp.legIso], PlanRole.secondary),
    Slot([_Mp.calf], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

/// Push / pull / legs, plus an upper and lower day. Five days is only offered to
/// people who already train; the extra frequency is wasted otherwise.
const _push = DayTemplate(
  title: 'Push',
  focus: 'Chest, shoulders and triceps',
  slots: [
    Slot([_Mp.horizontalPush], PlanRole.main),
    Slot([_Mp.verticalPush], PlanRole.main),
    Slot([_Mp.horizontalPush, _Mp.chestIso], PlanRole.secondary),
    Slot([_Mp.shoulderIso], PlanRole.accessory),
    Slot([_Mp.armTriceps], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

const _pull = DayTemplate(
  title: 'Pull',
  focus: 'Back and biceps',
  slots: [
    Slot([_Mp.verticalPull], PlanRole.main),
    Slot([_Mp.horizontalPull], PlanRole.main),
    Slot([_Mp.horizontalPull, _Mp.backIso], PlanRole.secondary),
    Slot([_Mp.shoulderIso], PlanRole.accessory, label: 'Rear shoulders'),
    Slot([_Mp.armBiceps], PlanRole.accessory),
    Slot([_Mp.grip, _Mp.core], PlanRole.accessory),
  ],
);

const _legs = DayTemplate(
  title: 'Legs',
  focus: 'Everything below the waist',
  slots: [
    Slot([_Mp.squat], PlanRole.main),
    Slot([_Mp.hinge], PlanRole.main),
    Slot([_Mp.lunge, _Mp.squat], PlanRole.secondary),
    Slot([_Mp.legIso], PlanRole.secondary),
    Slot([_Mp.calf], PlanRole.accessory),
    Slot([_Mp.core], PlanRole.accessory),
  ],
);

/// The split for a given number of training days.
List<DayTemplate> splitFor(int daysPerWeek) => switch (daysPerWeek) {
  2 => const [_fullBodyA, _fullBodyB],
  3 => const [_fullBodyA, _fullBodyB, _fullBodyC],
  4 => const [_upperA, _lowerA, _upperB, _lowerB],
  _ => const [_push, _pull, _legs, _upperA, _lowerA],
};

/// The name and one-line rationale shown when the plan is revealed.
({String name, String description}) splitIdentity(
  int daysPerWeek,
) => switch (daysPerWeek) {
  2 => (
    name: 'Two-Day Full Body',
    description:
        'Two full-body sessions a week. Every session trains everything, so '
        'missing one costs you very little.',
  ),
  3 => (
    name: 'Three-Day Full Body',
    description:
        'The classic beginner programme. Three full-body sessions, a rest '
        'day between each, and enough repetition to actually learn the lifts.',
  ),
  4 => (
    name: 'Upper / Lower Split',
    description:
        'Four days, alternating upper and lower body. More volume per muscle '
        'than full body, with a day of recovery built in between.',
  ),
  _ => (
    name: 'Push / Pull / Legs +',
    description:
        'Five days built around pushing, pulling and legs, then a second '
        'upper and lower day. Highest volume; needs consistent sleep and food.',
  ),
};
