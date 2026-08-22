import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_guide/data/models/exercise.dart';
import 'package:workout_guide/data/models/plan.dart';
import 'package:workout_guide/data/models/profile.dart';
import 'package:workout_guide/data/plan/plan_generator.dart';

/// The plan generator is the one piece of this app that can quietly do harm: a
/// bad plan puts a novice under a barbell they cannot handle, or hands someone
/// with a pair of dumbbells a week of cable machines. These tests assert the
/// guarantees that matter, over the real 1,324-exercise library rather than a
/// fixture, because the failure modes are all about what the real data contains.
void main() {
  late List<Exercise> library;

  setUpAll(() {
    final raw = File('assets/data/exercises.json').readAsStringSync();
    library = (jsonDecode(raw) as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  test('library loads and every record is usable', () {
    expect(library.length, 1324);
    for (final e in library) {
      expect(e.id, matches(RegExp(r'^\d{4}$')));
      expect(e.name.trim(), isNotEmpty);
      expect(e.steps, isNotEmpty, reason: '${e.name} has no instructions');
      // A movement with no target muscle cannot be placed on the body map.
      expect(e.target.trim(), isNotEmpty);
    }
  });

  group('generated plans', () {
    /// Every combination of answers onboarding can produce.
    final profiles = <Profile>[
      for (final goal in Goal.values)
        for (final experience in Experience.values)
          for (final days in [2, 3, 4, 5])
            Profile(
              goal: goal,
              experience: experience,
              daysPerWeek: days,
              equipment: const {
                EquipClass.bodyweight,
                EquipClass.dumbbell,
                EquipClass.machine,
                EquipClass.cable,
                EquipClass.barbell,
                EquipClass.cardioMachine,
              },
            ),
    ];

    test('never prescribes anything above the user\'s level', () {
      final generator = PlanGenerator(library);
      final byId = {for (final e in library) e.id: e};

      for (final profile in profiles) {
        final plan = generator.generate(profile);
        for (final day in plan.days) {
          for (final item in day.items) {
            final exercise = byId[item.exerciseId]!;
            expect(
              exercise.difficulty.index,
              lessThanOrEqualTo(profile.experience.ceiling.index),
              reason:
                  '${exercise.name} (${exercise.difficulty.label}) was given '
                  'to a ${profile.experience.label} user',
            );
          }
        }
      }
    });

    test('only uses equipment the user said they have', () {
      final generator = PlanGenerator(library);
      final byId = {for (final e in library) e.id: e};

      // The hardest case: someone training at home with nothing.
      const bodyweightOnly = Profile(
        experience: Experience.never,
        daysPerWeek: 3,
        equipment: {EquipClass.bodyweight},
      );

      final plan = generator.generate(bodyweightOnly);
      for (final day in plan.days) {
        for (final item in day.items) {
          final exercise = byId[item.exerciseId]!;
          expect(
            exercise.equipClass,
            EquipClass.bodyweight,
            reason: '${exercise.name} needs ${exercise.equipment}',
          );
        }
      }
    });

    test('every day has real work in it', () {
      final generator = PlanGenerator(library);

      for (final profile in profiles) {
        final plan = generator.generate(profile);
        expect(plan.days, hasLength(profile.daysPerWeek));

        for (final day in plan.days) {
          final working = day.workingItems;
          expect(
            working.length,
            greaterThanOrEqualTo(4),
            reason:
                '${plan.name} / ${day.title} only has ${working.length} '
                'working exercises',
          );
          expect(day.title.trim(), isNotEmpty);
          expect(day.focus.trim(), isNotEmpty);
        }
      }
    });

    test('sessions stay within a length a beginner will actually finish', () {
      final generator = PlanGenerator(library);

      for (final profile in profiles) {
        final plan = generator.generate(profile);
        for (final day in plan.days) {
          expect(
            day.estimatedMinutes,
            inInclusiveRange(20, 90),
            reason:
                '${day.title} is estimated at ${day.estimatedMinutes} '
                'minutes for a ${profile.experience.label} / '
                '${profile.goal.label} user',
          );
        }
      }
    });

    test('a complete novice is never given low-rep heavy work', () {
      final generator = PlanGenerator(library);

      for (final goal in Goal.values) {
        final plan = generator.generate(
          Profile(
            goal: goal,
            experience: Experience.never,
            daysPerWeek: 3,
            equipment: const {
              EquipClass.bodyweight,
              EquipClass.machine,
              EquipClass.dumbbell,
            },
          ),
        );

        for (final day in plan.days) {
          for (final item in day.workingItems) {
            // Five hard reps of a lift you cannot yet perform is the worst of
            // both worlds -- high risk, little learning.
            expect(
              item.repLow,
              greaterThanOrEqualTo(8),
              reason:
                  'A never-trained user was given ${item.repLow} reps '
                  'on a ${goal.label} plan',
            );
          }
        }
      }
    });

    test('a week is balanced between pushing and pulling', () {
      final generator = PlanGenerator(library);
      final byId = {for (final e in library) e.id: e};

      for (final profile in profiles) {
        final plan = generator.generate(profile);

        var pushes = 0;
        var pulls = 0;
        for (final day in plan.days) {
          for (final item in day.workingItems) {
            final pattern = byId[item.exerciseId]!.pattern;
            if (pattern == MovementPattern.horizontalPush ||
                pattern == MovementPattern.verticalPush) {
              pushes++;
            }
            if (pattern == MovementPattern.horizontalPull ||
                pattern == MovementPattern.verticalPull) {
              pulls++;
            }
          }
        }

        // Beginners overtrain what they see in the mirror. A generated plan
        // must not do it for them.
        expect(pulls, greaterThan(0), reason: '${plan.name} has no pulling');
        expect(pushes, greaterThan(0), reason: '${plan.name} has no pushing');
        expect(
          (pushes - pulls).abs(),
          lessThanOrEqualTo(3),
          reason:
              '${plan.name} for a ${profile.experience.label} user has '
              '$pushes pushes against $pulls pulls',
        );
      }
    });

    test('warm-up comes first and cool-down comes last', () {
      final generator = PlanGenerator(library);

      for (final profile in profiles.take(12)) {
        final plan = generator.generate(profile);
        for (final day in plan.days) {
          final roles = day.items.map((i) => i.role).toList();

          final warmupIndex = roles.indexOf(PlanRole.warmup);
          if (warmupIndex != -1) expect(warmupIndex, 0);

          final firstCooldown = roles.indexOf(PlanRole.cooldown);
          if (firstCooldown != -1) {
            expect(
              roles.sublist(firstCooldown).every((r) => r == PlanRole.cooldown),
              isTrue,
              reason: '${day.title} has working sets after the cool-down',
            );
          }
        }
      }
    });

    test('regenerating gives a genuinely different plan', () {
      final generator = PlanGenerator(library);
      const profile = Profile(
        goal: Goal.muscle,
        experience: Experience.some,
        daysPerWeek: 3,
        equipment: {
          EquipClass.bodyweight,
          EquipClass.dumbbell,
          EquipClass.machine,
          EquipClass.cable,
          EquipClass.barbell,
        },
      );

      List<String> idsOf(Plan plan) => [
        for (final day in plan.days)
          for (final item in day.workingItems) item.exerciseId,
      ];

      final first = idsOf(generator.generate(profile, nonce: 0));
      final second = idsOf(generator.generate(profile, nonce: 1));

      expect(first, isNot(equals(second)));
    });

    test('the same answers and nonce always give the same plan', () {
      final generator = PlanGenerator(library);
      const profile = Profile(
        goal: Goal.strength,
        experience: Experience.regular,
        daysPerWeek: 4,
        equipment: {
          EquipClass.barbell,
          EquipClass.dumbbell,
          EquipClass.machine,
        },
      );

      final a = generator.generate(profile, nonce: 7);
      final b = generator.generate(profile, nonce: 7);

      for (var d = 0; d < a.days.length; d++) {
        expect(
          a.days[d].items.map((i) => i.exerciseId),
          b.days[d].items.map((i) => i.exerciseId),
        );
      }
    });
  });

  group('alternatives', () {
    test('always share the movement pattern of what they replace', () {
      final generator = PlanGenerator(library);
      const profile = Profile(
        experience: Experience.regular,
        equipment: {
          EquipClass.bodyweight,
          EquipClass.dumbbell,
          EquipClass.machine,
        },
      );

      for (final exercise in library.take(120)) {
        for (final alternative in generator.alternativesFor(
          exercise,
          profile,
        )) {
          expect(alternative.pattern, exercise.pattern);
          expect(alternative.id, isNot(exercise.id));
          expect(
            alternative.difficulty.index,
            lessThanOrEqualTo(profile.experience.ceiling.index),
          );
        }
      }
    });

    test('put the kit the user actually owns first', () {
      final generator = PlanGenerator(library);
      const profile = Profile(equipment: {EquipClass.bodyweight});

      final barbellSquat = library.firstWhere(
        (e) => e.name == 'Barbell Full Squat',
      );
      final options = generator.alternativesFor(barbellSquat, profile);

      if (options.isNotEmpty) {
        expect(options.first.equipClass, EquipClass.bodyweight);
      }
    });
  });

  group('serialisation round-trips', () {
    test('a plan survives being written and read back', () {
      final generator = PlanGenerator(library);
      const profile = Profile(
        daysPerWeek: 3,
        equipment: {EquipClass.bodyweight},
      );
      final original = generator.generate(profile);

      final restored = Plan.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.name, original.name);
      expect(restored.days.length, original.days.length);
      for (var d = 0; d < original.days.length; d++) {
        expect(
          restored.days[d].items.map((i) => i.exerciseId),
          original.days[d].items.map((i) => i.exerciseId),
        );
        expect(
          restored.days[d].items.map((i) => i.restSeconds),
          original.days[d].items.map((i) => i.restSeconds),
        );
      }
    });

    test('a profile survives being written and read back', () {
      const original = Profile(
        name: 'Sam',
        goal: Goal.lean,
        experience: Experience.some,
        daysPerWeek: 4,
        equipment: {EquipClass.dumbbell, EquipClass.band},
        units: Units.imperial,
        restTimerEnabled: false,
        onboarded: true,
      );

      final restored = Profile.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.name, 'Sam');
      expect(restored.goal, Goal.lean);
      expect(restored.experience, Experience.some);
      expect(restored.daysPerWeek, 4);
      expect(restored.equipment, original.equipment);
      expect(restored.units, Units.imperial);
      expect(restored.restTimerEnabled, isFalse);
      expect(restored.onboarded, isTrue);
    });
  });
}
