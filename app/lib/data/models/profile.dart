import 'package:flutter/foundation.dart';

import 'exercise.dart';

enum Goal {
  muscle(
    'Build muscle',
    'Add size and shape',
    'Moderate weights, 8-12 reps, short rests. The classic muscle-building recipe.',
  ),
  strength(
    'Get stronger',
    'Lift heavier over time',
    'Heavier weights, 4-6 reps, long rests so you can repeat the effort.',
  ),
  lean(
    'Lose fat, keep muscle',
    'Leaner, not smaller',
    'Full-body work with short rests, so sessions burn more while keeping muscle.',
  ),
  health(
    'Get fit and healthy',
    'Feel better day to day',
    'Balanced sessions at a comfortable intensity. The easiest one to stick to.',
  );

  const Goal(this.label, this.blurb, this.explainer);
  final String label;
  final String blurb;
  final String explainer;
}

enum Experience {
  never(
    'Never trained',
    "I've never done this before",
    'Machines and simple movements only, so nothing can go badly wrong while you learn.',
  ),
  some(
    'Tried it before',
    'A few months, on and off',
    'Free weights come in, with the technical lifts held back until you have a base.',
  ),
  regular(
    'Training regularly',
    'Comfortable in a gym',
    'The full library, including barbell work and single-sided movements.',
  );

  const Experience(this.label, this.blurb, this.explainer);
  final String label;
  final String blurb;
  final String explainer;

  /// The hardest thing we will ever put in this person's plan.
  Difficulty get ceiling => switch (this) {
    Experience.never => Difficulty.beginner,
    Experience.some => Difficulty.intermediate,
    Experience.regular => Difficulty.advanced,
  };
}

enum Units {
  metric('kg', 'Kilograms'),
  imperial('lb', 'Pounds');

  const Units(this.suffix, this.label);
  final String suffix;
  final String label;
}

/// Everything onboarding collects, plus the settings that follow from it.
@immutable
class Profile {
  const Profile({
    this.name = '',
    this.goal = Goal.health,
    this.experience = Experience.never,
    this.daysPerWeek = 3,
    this.equipment = const {EquipClass.bodyweight},
    this.units = Units.metric,
    this.restTimerEnabled = true,
    this.onboarded = false,
    this.createdAt,
  });

  final String name;
  final Goal goal;
  final Experience experience;

  /// 2 to 5. Above 5 a beginner's problem is recovery, not volume, so we do not
  /// offer it.
  final int daysPerWeek;

  final Set<EquipClass> equipment;
  final Units units;
  final bool restTimerEnabled;
  final bool onboarded;
  final DateTime? createdAt;

  String get greetingName =>
      name.trim().isEmpty ? '' : name.trim().split(' ').first;

  Profile copyWith({
    String? name,
    Goal? goal,
    Experience? experience,
    int? daysPerWeek,
    Set<EquipClass>? equipment,
    Units? units,
    bool? restTimerEnabled,
    bool? onboarded,
    DateTime? createdAt,
  }) => Profile(
    name: name ?? this.name,
    goal: goal ?? this.goal,
    experience: experience ?? this.experience,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    equipment: equipment ?? this.equipment,
    units: units ?? this.units,
    restTimerEnabled: restTimerEnabled ?? this.restTimerEnabled,
    onboarded: onboarded ?? this.onboarded,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'goal': goal.name,
    'experience': experience.name,
    'daysPerWeek': daysPerWeek,
    'equipment': equipment.map((e) => e.storageKey).toList(),
    'units': units.name,
    'restTimerEnabled': restTimerEnabled,
    'onboarded': onboarded,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] as String? ?? '',
    goal: Goal.values.firstWhere(
      (g) => g.name == json['goal'],
      orElse: () => Goal.health,
    ),
    experience: Experience.values.firstWhere(
      (e) => e.name == json['experience'],
      orElse: () => Experience.never,
    ),
    daysPerWeek: json['daysPerWeek'] as int? ?? 3,
    equipment: {
      for (final k in (json['equipment'] as List? ?? const []).cast<String>())
        EquipClass.fromKey(k),
    },
    units: Units.values.firstWhere(
      (u) => u.name == json['units'],
      orElse: () => Units.metric,
    ),
    restTimerEnabled: json['restTimerEnabled'] as bool? ?? true,
    onboarded: json['onboarded'] as bool? ?? false,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.tryParse(json['createdAt'] as String),
  );
}
