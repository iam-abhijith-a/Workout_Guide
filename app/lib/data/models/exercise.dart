import 'package:flutter/foundation.dart';

/// How hard a movement is to perform *correctly*, which is a different question
/// from how heavy it is. A machine chest press is beginner because the path is
/// fixed; a barbell back squat is not, at any weight.
enum Difficulty {
  beginner('Beginner', 'Safe to learn on your own'),
  intermediate('Intermediate', 'Needs some technique'),
  advanced('Advanced', 'Get coached before trying');

  const Difficulty(this.label, this.blurb);
  final String label;
  final String blurb;

  static Difficulty fromIndex(int i) =>
      i <= 0 ? beginner : (i == 1 ? intermediate : advanced);
}

/// The fundamental movement patterns. A week of training is balanced when these
/// are balanced -- which is why the plan generator picks by pattern, never by
/// muscle name.
enum MovementPattern {
  squat('Squat', 'Bending at the knees under load'),
  hinge('Hinge', 'Bending at the hips, back stays flat'),
  lunge('Lunge', 'One leg in front of the other'),
  horizontalPush('Horizontal push', 'Pressing away from your chest'),
  verticalPush('Vertical push', 'Pressing overhead'),
  horizontalPull('Horizontal pull', 'Rowing toward your torso'),
  verticalPull('Vertical pull', 'Pulling down from above'),
  core('Core', 'Bracing and resisting movement'),
  legIso('Leg accessory', 'One joint, one leg muscle'),
  chestIso('Chest accessory', 'Chest on its own'),
  backIso('Back accessory', 'Back on its own'),
  armBiceps('Biceps', 'Bending the elbow'),
  armTriceps('Triceps', 'Straightening the elbow'),
  shoulderIso('Shoulder accessory', 'Raising the arm'),
  calf('Calves', 'Rising onto the toes'),
  grip('Grip & forearms', 'Holding on'),
  neck('Neck', 'Neck strength'),
  carry('Carry', 'Walking under load'),
  plyo('Explosive', 'Jumping and throwing'),
  cardio('Cardio', 'Raising your heart rate'),
  stretch('Stretch', 'Lengthening and mobility'),
  isolation('Accessory', 'Single-joint work');

  const MovementPattern(this.label, this.blurb);
  final String label;
  final String blurb;

  static const _byKey = <String, MovementPattern>{
    'squat': squat,
    'hinge': hinge,
    'lunge': lunge,
    'horizontal_push': horizontalPush,
    'vertical_push': verticalPush,
    'horizontal_pull': horizontalPull,
    'vertical_pull': verticalPull,
    'core': core,
    'leg_iso': legIso,
    'chest_iso': chestIso,
    'back_iso': backIso,
    'arm_biceps': armBiceps,
    'arm_triceps': armTriceps,
    'shoulder_iso': shoulderIso,
    'calf': calf,
    'grip': grip,
    'neck': neck,
    'carry': carry,
    'plyo': plyo,
    'cardio': cardio,
    'stretch': stretch,
    'isolation': isolation,
  };

  static MovementPattern fromKey(String key) => _byKey[key] ?? isolation;

  bool get isCompound => const {
    squat,
    hinge,
    lunge,
    horizontalPush,
    verticalPush,
    horizontalPull,
    verticalPull,
  }.contains(this);
}

/// What the user has to train with. Everything in the library is tagged with one,
/// and everything the plan generator picks has to be in the user's set.
enum EquipClass {
  bodyweight('Body weight', 'Nothing but you'),
  dumbbell('Dumbbells', 'A pair of adjustable or fixed dumbbells'),
  barbell('Barbell', 'Bar, plates and a rack'),
  machine('Machines', 'Plate-loaded and selectorised machines'),
  cable('Cables', 'Adjustable cable stack'),
  band('Resistance bands', 'Loop or tube bands'),
  kettlebell('Kettlebells', 'One or more bells'),
  ball('Exercise ball', 'Stability, medicine or BOSU ball'),
  cardioMachine('Cardio machines', 'Bike, elliptical, stair machine'),
  other('Specialist kit', 'Sleds, tyres, ab wheels');

  const EquipClass(this.label, this.blurb);
  final String label;
  final String blurb;

  static const _byKey = <String, EquipClass>{
    'bodyweight': bodyweight,
    'dumbbell': dumbbell,
    'barbell': barbell,
    'machine': machine,
    'cable': cable,
    'band': band,
    'kettlebell': kettlebell,
    'ball': ball,
    'cardio_machine': cardioMachine,
    'other': other,
  };

  static EquipClass fromKey(String key) => _byKey[key] ?? other;

  String get storageKey =>
      _byKey.entries.firstWhere((e) => e.value == this).key;
}

/// Kit a movement needs when there is no gym.
///
/// A floor and a wall are assumed, so the empty set -- "you need nothing" -- is
/// the most common and the most useful case. Everything else is named, because
/// hiding a movement someone cannot do is only possible if we know what it asks
/// for, which the source data never says.
enum HomeGear {
  dumbbell('Dumbbells', 'Dumbbells', 'A pair, any weight'),
  pullUpBar('Pull-up bar', 'Bar', 'A doorway bar is enough'),
  bench('Bench or chair', 'Bench', 'A sofa, a stair, a sturdy chair'),
  band('Band', 'Band', 'A loop or a tube band');

  const HomeGear(this.label, this.short, this.blurb);

  final String label;

  /// For a card, where "Bench or chair" would take the whole line.
  final String short;
  final String blurb;

  static const _byKey = <String, HomeGear>{
    'dumbbell': dumbbell,
    'pullup_bar': pullUpBar,
    'bench': bench,
    'band': band,
  };

  static HomeGear? fromKey(String key) => _byKey[key];

  String get storageKey =>
      _byKey.entries.firstWhere((e) => e.value == this).key;
}

@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.equipClass,
    required this.target,
    required this.secondary,
    required this.pattern,
    required this.difficulty,
    required this.compound,
    required this.unilateral,
    required this.steps,
    required this.searchIndex,
    required this.homeGear,
  });

  final String id;
  final String name;

  /// The dataset's coarse region: chest, back, upper legs, waist...
  final String bodyPart;

  /// The specific piece of kit, e.g. "leverage machine". [equipClass] is the
  /// bucket this belongs to.
  final String equipment;
  final EquipClass equipClass;

  /// Primary muscle worked.
  final String target;
  final List<String> secondary;

  final MovementPattern pattern;
  final Difficulty difficulty;
  final bool compound;

  /// One side at a time, so a "set" means a set per side.
  final bool unilateral;

  final List<String> steps;

  /// Lower-cased haystack, precomputed once at load so search stays allocation-free.
  final String searchIndex;

  /// What this needs to be done at home, or null when it needs a gym. Empty
  /// means a floor and nothing else.
  final Set<HomeGear>? homeGear;

  bool get isHomeFriendly => homeGear != null;

  /// True when someone with [kit] can do this in their living room.
  bool doableWith(Set<HomeGear> kit) {
    final gear = homeGear;
    return gear != null && gear.every(kit.contains);
  }

  String get thumbAsset => 'assets/thumb/$id.jpg';
  String get animAsset => 'assets/anim/$id.webp';

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final target = json['target'] as String;
    final equipment = json['equipment'] as String;
    final bodyPart = json['bodyPart'] as String;
    final secondary = (json['secondary'] as List).cast<String>();
    final pattern = MovementPattern.fromKey(json['pattern'] as String);
    final home = json['home'] as List?;
    return Exercise(
      id: json['id'] as String,
      name: name,
      bodyPart: bodyPart,
      equipment: equipment,
      equipClass: EquipClass.fromKey(json['equipClass'] as String),
      target: target,
      secondary: secondary,
      pattern: pattern,
      difficulty: Difficulty.fromIndex(json['difficulty'] as int),
      compound: json['compound'] as bool,
      unilateral: json['unilateral'] as bool,
      steps: (json['steps'] as List).cast<String>(),
      // Absent means "needs a gym"; present but empty means "needs a floor".
      // The two are different answers and the null carries one of them.
      homeGear: home == null
          ? null
          : {
              for (final key in home.cast<String>())
                if (HomeGear.fromKey(key) case final gear?) gear,
            },
      searchIndex:
          '$name $bodyPart $target $equipment ${secondary.join(' ')} '
                  '${pattern.label}'
              .toLowerCase(),
    );
  }

  @override
  bool operator ==(Object other) => other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
