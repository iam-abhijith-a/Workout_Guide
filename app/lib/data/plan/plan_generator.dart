import 'dart:math';

import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/profile.dart';
import 'slot_templates.dart';

/// Builds a week of training from onboarding answers.
///
/// The job is not "pick some exercises". It is to produce something a beginner
/// can follow without a coach: nothing above their level, nothing needing kit
/// they do not have, balanced across movement patterns, and short enough that
/// they actually finish it.
class PlanGenerator {
  PlanGenerator(this.library);

  final List<Exercise> library;

  /// [nonce] changes the deterministic shuffle, so "regenerate" produces a
  /// genuinely different plan from the same answers rather than the same one.
  Plan generate(Profile profile, {int nonce = 0}) {
    final rng = Random(
      Object.hash(
        profile.goal,
        profile.experience,
        profile.daysPerWeek,
        profile.equipment.length,
        nonce,
      ),
    );

    final templates = splitFor(profile.daysPerWeek);
    final identity = splitIdentity(profile.daysPerWeek);

    // Exercises already used this week. Repeating the same movement on every day
    // is technically valid and feels like a broken app, so we spread out.
    final used = <String>{};
    final days = <PlanDay>[];

    for (var i = 0; i < templates.length; i++) {
      days.add(_buildDay(templates[i], i, profile, rng, used));
    }

    return Plan(
      name: identity.name,
      description: identity.description,
      days: days,
      generatedAt: DateTime.now(),
    );
  }

  PlanDay _buildDay(
    DayTemplate template,
    int index,
    Profile profile,
    Random rng,
    Set<String> used,
  ) {
    final slots = template.slots.take(_workingExercises(profile)).toList();
    final items = <PlanItem>[];

    final warmup = _pickWarmup(profile, rng);
    if (warmup != null) items.add(warmup);

    for (final slot in slots) {
      final picked = _pickForSlot(slot, profile, rng, used);
      if (picked == null) continue;
      used.add(picked.id);
      items.add(_prescribe(picked, slot.role, profile));
    }

    items.addAll(_pickCooldown(items, profile, rng));

    return PlanDay(
      index: index,
      title: template.title,
      focus: template.focus,
      items: items,
    );
  }

  /// How many working exercises a session gets.
  ///
  /// Capped low for a true beginner on purpose. The failure mode for someone new
  /// is not "too little volume", it is a 90-minute session they never repeat.
  int _workingExercises(Profile profile) => switch (profile.experience) {
    Experience.never => 4,
    Experience.some => 5,
    Experience.regular => profile.daysPerWeek >= 4 ? 6 : 5,
  };

  Exercise? _pickForSlot(
    Slot slot,
    Profile profile,
    Random rng,
    Set<String> used,
  ) {
    // Tried in order: the exact pattern with everything satisfied, then the
    // fallback patterns, then the same patterns allowing a repeat from earlier
    // in the week. Only if all of that fails does the slot go unfilled.
    for (final allowRepeat in [false, true]) {
      for (final pattern in slot.patterns) {
        final candidates = library.where((e) {
          if (e.pattern != pattern) return false;
          if (e.difficulty.index > profile.experience.ceiling.index) {
            return false;
          }
          if (!profile.equipment.contains(e.equipClass)) return false;
          if (!allowRepeat && used.contains(e.id)) return false;
          return true;
        }).toList();

        if (candidates.isEmpty) continue;

        final scored =
            candidates.map((e) => (e, _score(e, slot, profile, rng))).toList()
              ..sort((a, b) => b.$2.compareTo(a.$2));

        // Pick from the top of the ranking rather than the single best, so two
        // people with identical answers do not get byte-identical plans.
        final window = min(4, scored.length);
        return scored[rng.nextInt(window)].$1;
      }
    }
    return null;
  }

  /// Ranks a candidate for a slot. Higher is better.
  double _score(Exercise e, Slot slot, Profile profile, Random rng) {
    var score = 0.0;

    // Prefer movements at the top of what this person can handle -- training at
    // the bottom of your ceiling forever is how people stall.
    final ceiling = profile.experience.ceiling.index;
    score += 2.0 - (ceiling - e.difficulty.index).abs();

    // Main slots want the big multi-joint lifts.
    if (slot.role == PlanRole.main && e.compound) score += 3;
    if (slot.role == PlanRole.accessory && !e.compound) score += 1;

    // Balance on one leg is a skill of its own. Do not make someone learn it at
    // the same time as learning to lift.
    if (e.unilateral && profile.experience == Experience.never) score -= 3;

    // Short, unqualified names are the canonical version of a movement.
    // "Dumbbell Bench Press" over "Dumbbell Decline Neutral Grip Bench Press".
    if (!e.name.contains('(')) score += 2;
    final words = e.name.split(' ').length;
    score += (6 - words).clamp(-3, 3) * 0.7;

    // Machines are more forgiving; free weights carry over better. Weight that
    // trade-off by how much the person actually knows.
    score += switch (profile.experience) {
      Experience.never => switch (e.equipClass) {
        EquipClass.machine || EquipClass.cable => 2.5,
        EquipClass.bodyweight || EquipClass.band => 1.5,
        EquipClass.dumbbell => 1.0,
        _ => -1.0,
      },
      Experience.some => switch (e.equipClass) {
        EquipClass.dumbbell || EquipClass.cable => 2.0,
        EquipClass.machine || EquipClass.bodyweight => 1.0,
        _ => 0.0,
      },
      Experience.regular => switch (e.equipClass) {
        EquipClass.barbell || EquipClass.dumbbell => 2.0,
        EquipClass.cable => 1.0,
        _ => 0.0,
      },
    };

    // Fat-loss and general-health plans lean on movements that use more muscle
    // at once, since that is what makes a session worth the time.
    if ((profile.goal == Goal.lean || profile.goal == Goal.health) &&
        e.compound) {
      score += 1;
    }

    return score + rng.nextDouble() * 0.6;
  }

  /// Turns an exercise into a prescription: sets, reps and rest.
  ///
  /// Rest is the number beginners get most wrong -- they either rush heavy sets
  /// or spend three minutes on a curl -- so it is prescribed explicitly and the
  /// timer runs it for them.
  PlanItem _prescribe(Exercise e, PlanRole role, Profile profile) {
    final isCompound = e.compound;

    var (sets, low, high, rest) = switch (profile.goal) {
      Goal.muscle => isCompound ? (3, 8, 12, 90) : (3, 10, 15, 60),
      Goal.strength => isCompound ? (4, 5, 6, 150) : (3, 8, 10, 90),
      Goal.lean => isCompound ? (3, 10, 12, 60) : (3, 12, 15, 45),
      Goal.health => isCompound ? (3, 8, 12, 75) : (2, 12, 15, 60),
    };

    // Someone brand new is learning the movement, not chasing a number. Fewer
    // sets, and never the heavy low-rep work -- five hard reps of a lift you
    // cannot yet perform is the worst of both worlds.
    if (profile.experience == Experience.never) {
      sets = max(2, sets - 1);
      if (low < 8) {
        low = 8;
        high = 12;
        rest = 90;
      }
    }

    if (role == PlanRole.accessory) sets = max(2, sets - 1);

    return PlanItem(
      exerciseId: e.id,
      sets: sets,
      repLow: low,
      repHigh: high,
      restSeconds: rest,
      role: role,
      note: e.unilateral ? 'Per side' : null,
    );
  }

  /// Five easy minutes to raise your temperature. Skipped rather than faked if
  /// there is nothing suitable -- a fake warm-up teaches a bad habit.
  PlanItem? _pickWarmup(Profile profile, Random rng) {
    final cardio = library
        .where(
          (e) =>
              e.pattern == MovementPattern.cardio &&
              e.difficulty == Difficulty.beginner &&
              profile.equipment.contains(e.equipClass),
        )
        .toList();

    if (cardio.isEmpty) return null;
    final pick = cardio[rng.nextInt(cardio.length)];
    return PlanItem(
      exerciseId: pick.id,
      sets: 1,
      repLow: 1,
      repHigh: 1,
      restSeconds: 0,
      role: PlanRole.warmup,
      note: 'Easy pace — you should still be able to talk.',
    );
  }

  /// Two stretches chosen for the muscles the session actually worked, rather
  /// than a generic list -- it is the difference between a cool-down and filler.
  List<PlanItem> _pickCooldown(
    List<PlanItem> items,
    Profile profile,
    Random rng,
  ) {
    final byId = {for (final e in library) e.id: e};
    final worked = <String>{
      for (final item in items)
        if (byId[item.exerciseId] case final e?) e.target,
    };

    // Filtered by equipment like everything else: prescribing a stability-ball
    // stretch to someone training in a bedroom is the same failure as
    // prescribing them a cable row.
    final stretches = library
        .where(
          (e) =>
              e.pattern == MovementPattern.stretch &&
              profile.equipment.contains(e.equipClass),
        )
        .toList();
    if (stretches.isEmpty) return const [];

    final relevant = stretches
        .where(
          (s) => worked.contains(s.target) || worked.any(s.secondary.contains),
        )
        .toList();
    final pool = relevant.length >= 2 ? relevant : stretches;

    pool.shuffle(rng);
    return pool
        .take(2)
        .map(
          (e) => PlanItem(
            exerciseId: e.id,
            sets: 1,
            repLow: 1,
            repHigh: 1,
            restSeconds: 0,
            role: PlanRole.cooldown,
            note: 'Hold 30 seconds each side.',
          ),
        )
        .toList();
  }

  /// Swaps one exercise for the closest alternative the user can actually do.
  ///
  /// Exists because "the machine is taken" and "that one hurts my shoulder" are
  /// the two most common reasons a plan gets abandoned mid-session.
  List<Exercise> alternativesFor(
    Exercise current,
    Profile profile, {
    int limit = 8,
  }) {
    final matches = library.where((e) {
      if (e.id == current.id) return false;
      if (e.pattern != current.pattern) return false;
      if (e.difficulty.index > profile.experience.ceiling.index) return false;
      return true;
    }).toList();

    matches.sort((a, b) {
      // Kit you actually have, first.
      final aHas = profile.equipment.contains(a.equipClass) ? 0 : 1;
      final bHas = profile.equipment.contains(b.equipClass) ? 0 : 1;
      if (aHas != bHas) return aHas - bHas;

      // Then the same target muscle.
      final aTarget = a.target == current.target ? 0 : 1;
      final bTarget = b.target == current.target ? 0 : 1;
      if (aTarget != bTarget) return aTarget - bTarget;

      return a.name.length.compareTo(b.name.length);
    });

    return matches.take(limit).toList();
  }
}
