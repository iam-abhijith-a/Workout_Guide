import '../../core/theme/tokens.dart';
import 'package:flutter/painting.dart';

/// Regions on the anatomical figure. Split front/back because that is how the
/// body actually reads -- highlighting "back" on a front-facing figure teaches
/// nobody anything.
enum MuscleRegion {
  chest(true),
  frontDelts(true),
  sideDelts(true),
  biceps(true),
  forearms(true),
  abs(true),
  obliques(true),
  quads(true),
  adductors(true),
  shinsFront(true),
  neckFront(true),
  traps(false),
  rearDelts(false),
  lats(false),
  upperBack(false),
  lowerBack(false),
  triceps(false),
  forearmsBack(false),
  glutes(false),
  hamstrings(false),
  calves(false),
  neckBack(false);

  const MuscleRegion(this.isFront);

  /// Whether this region is drawn on the front-facing figure.
  final bool isFront;
}

/// Which muscle family a region belongs to, for colour.
Color regionColor(MuscleRegion r) => switch (r) {
  MuscleRegion.chest => FColors.partChest,
  MuscleRegion.lats ||
  MuscleRegion.upperBack ||
  MuscleRegion.lowerBack ||
  MuscleRegion.traps => FColors.partBack,
  MuscleRegion.quads ||
  MuscleRegion.hamstrings ||
  MuscleRegion.glutes ||
  MuscleRegion.calves ||
  MuscleRegion.adductors ||
  MuscleRegion.shinsFront => FColors.partLegs,
  MuscleRegion.frontDelts ||
  MuscleRegion.sideDelts ||
  MuscleRegion.rearDelts => FColors.partShoulders,
  MuscleRegion.biceps ||
  MuscleRegion.triceps ||
  MuscleRegion.forearms ||
  MuscleRegion.forearmsBack => FColors.partArms,
  MuscleRegion.abs || MuscleRegion.obliques => FColors.partCore,
  MuscleRegion.neckFront || MuscleRegion.neckBack => FColors.partCardio,
};

/// Maps the dataset's muscle vocabulary onto figure regions.
///
/// The dataset uses three overlapping vocabularies -- `target`, `muscle_group`
/// and `secondary_muscles` -- with names like "traps", "trapezius" and "upper
/// back" all in play, so this table has to be generous.
const Map<String, List<MuscleRegion>> _muscleRegions = {
  // Targets
  'pectorals': [MuscleRegion.chest],
  'chest': [MuscleRegion.chest],
  'upper chest': [MuscleRegion.chest],
  'serratus anterior': [MuscleRegion.obliques],
  'delts': [
    MuscleRegion.frontDelts,
    MuscleRegion.sideDelts,
    MuscleRegion.rearDelts,
  ],
  'deltoids': [
    MuscleRegion.frontDelts,
    MuscleRegion.sideDelts,
    MuscleRegion.rearDelts,
  ],
  'shoulders': [
    MuscleRegion.frontDelts,
    MuscleRegion.sideDelts,
    MuscleRegion.rearDelts,
  ],
  'rear deltoids': [MuscleRegion.rearDelts],
  'rotator cuff': [MuscleRegion.rearDelts],
  'biceps': [MuscleRegion.biceps],
  'brachialis': [MuscleRegion.biceps],
  'triceps': [MuscleRegion.triceps],
  'forearms': [MuscleRegion.forearms, MuscleRegion.forearmsBack],
  'wrist flexors': [MuscleRegion.forearms],
  'wrist extensors': [MuscleRegion.forearmsBack],
  'wrists': [MuscleRegion.forearms, MuscleRegion.forearmsBack],
  'hands': [MuscleRegion.forearms],
  'grip muscles': [MuscleRegion.forearms],
  'abs': [MuscleRegion.abs],
  'abdominals': [MuscleRegion.abs],
  'lower abs': [MuscleRegion.abs],
  'core': [MuscleRegion.abs, MuscleRegion.obliques],
  'obliques': [MuscleRegion.obliques],
  'hip flexors': [MuscleRegion.quads, MuscleRegion.abs],
  'spine': [MuscleRegion.lowerBack],
  'lower back': [MuscleRegion.lowerBack],
  'lats': [MuscleRegion.lats],
  'latissimus dorsi': [MuscleRegion.lats],
  'upper back': [MuscleRegion.upperBack],
  'back': [MuscleRegion.lats, MuscleRegion.upperBack],
  'rhomboids': [MuscleRegion.upperBack],
  'traps': [MuscleRegion.traps],
  'trapezius': [MuscleRegion.traps],
  'levator scapulae': [MuscleRegion.neckBack, MuscleRegion.traps],
  'sternocleidomastoid': [MuscleRegion.neckFront],
  'glutes': [MuscleRegion.glutes],
  'quads': [MuscleRegion.quads],
  'quadriceps': [MuscleRegion.quads],
  'hamstrings': [MuscleRegion.hamstrings],
  'calves': [MuscleRegion.calves],
  'soleus': [MuscleRegion.calves],
  'shins': [MuscleRegion.shinsFront],
  'ankles': [MuscleRegion.calves],
  'ankle stabilizers': [MuscleRegion.calves],
  'feet': [MuscleRegion.calves],
  'adductors': [MuscleRegion.adductors],
  'inner thighs': [MuscleRegion.adductors],
  'groin': [MuscleRegion.adductors],
  'abductors': [MuscleRegion.glutes],
  'cardiovascular system': [],
};

List<MuscleRegion> regionsForMuscle(String muscle) =>
    _muscleRegions[muscle.toLowerCase()] ?? const [];

/// Plain-English descriptions, because "lats" means nothing to someone new.
const Map<String, String> muscleExplainers = {
  'pectorals': 'Your chest. Pushes things away from you.',
  'lats':
      'The wide muscles down the sides of your back. They pull your arms down and in.',
  'upper back': 'Between your shoulder blades. Holds your posture up all day.',
  'traps': 'From your neck to your shoulders. Shrugs and carries.',
  'delts': 'Your shoulders. Raises your arms in every direction.',
  'biceps': 'Front of your upper arm. Bends your elbow.',
  'triceps':
      'Back of your upper arm. Straightens your elbow -- and it is the bigger half.',
  'forearms': 'Below the elbow. Your grip.',
  'abs': 'Front of your stomach. Bends and braces your trunk.',
  'spine':
      'The muscles running alongside your spine. Keeps your back straight under load.',
  'quads': 'Front of your thigh. Straightens your knee.',
  'hamstrings': 'Back of your thigh. Bends your knee and extends your hip.',
  'glutes': 'Your backside. The strongest muscle you have.',
  'calves': 'Back of your lower leg. Every step you take.',
  'adductors': 'Inner thigh. Pulls your legs together.',
  'abductors': 'Outer hip. Pushes your legs apart and stabilises every step.',
  'serratus anterior':
      'The finger-like muscles over your ribs. Moves your shoulder blade.',
  'levator scapulae': 'Side of your neck. Where phone-neck tension lives.',
  'cardiovascular system': 'Your heart and lungs.',
};

String explainMuscle(String muscle) =>
    muscleExplainers[muscle.toLowerCase()] ?? '';

/// Colour for a dataset body-part label, used on library cards.
Color bodyPartColor(String bodyPart) => switch (bodyPart) {
  'chest' => FColors.partChest,
  'back' => FColors.partBack,
  'upper legs' || 'lower legs' => FColors.partLegs,
  'shoulders' => FColors.partShoulders,
  'upper arms' || 'lower arms' => FColors.partArms,
  'waist' => FColors.partCore,
  'cardio' => FColors.partCardio,
  _ => FColors.textMuted,
};
