import 'package:flutter/foundation.dart';

import 'plan.dart';

/// One set, as actually performed. `targetReps` is what the plan asked for;
/// `reps` is what happened. Keeping both is what makes progress legible later.
@immutable
class SetLog {
  const SetLog({
    required this.targetReps,
    this.reps,
    this.weight,
    this.done = false,
  });

  final int targetReps;
  final int? reps;
  final double? weight;
  final bool done;

  double get volume => (reps ?? 0) * (weight ?? 0);

  SetLog copyWith({int? reps, double? weight, bool? done, int? targetReps}) =>
      SetLog(
        targetReps: targetReps ?? this.targetReps,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
    'targetReps': targetReps,
    'reps': reps,
    'weight': weight,
    'done': done,
  };

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
    targetReps: json['targetReps'] as int? ?? 10,
    reps: json['reps'] as int?,
    weight: (json['weight'] as num?)?.toDouble(),
    done: json['done'] as bool? ?? false,
  );
}

@immutable
class ExerciseLog {
  const ExerciseLog({
    required this.exerciseId,
    required this.name,
    required this.role,
    required this.sets,
    required this.restSeconds,
    this.skipped = false,
  });

  final String exerciseId;

  /// Denormalised so history stays readable even if the library changes.
  final String name;
  final PlanRole role;
  final List<SetLog> sets;
  final int restSeconds;
  final bool skipped;

  bool get isComplete => sets.every((s) => s.done);
  int get completedSets => sets.where((s) => s.done).length;
  double get volume => sets.fold(0, (sum, s) => sum + s.volume);

  ExerciseLog copyWith({List<SetLog>? sets, bool? skipped}) => ExerciseLog(
    exerciseId: exerciseId,
    name: name,
    role: role,
    sets: sets ?? this.sets,
    restSeconds: restSeconds,
    skipped: skipped ?? this.skipped,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'role': role.name,
    'sets': sets.map((s) => s.toJson()).toList(),
    'restSeconds': restSeconds,
    'skipped': skipped,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    exerciseId: json['exerciseId'] as String,
    name: json['name'] as String,
    role: PlanRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => PlanRole.main,
    ),
    sets: (json['sets'] as List)
        .map((s) => SetLog.fromJson(s as Map<String, dynamic>))
        .toList(),
    restSeconds: json['restSeconds'] as int? ?? 60,
    skipped: json['skipped'] as bool? ?? false,
  );
}

/// A workout, in progress or finished.
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.dayTitle,
    required this.dayFocus,
    required this.startedAt,
    required this.exercises,
    this.finishedAt,
    this.currentIndex = 0,
  });

  final String id;
  final String dayTitle;
  final String dayFocus;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<ExerciseLog> exercises;
  final int currentIndex;

  bool get isFinished => finishedAt != null;

  Duration get duration => (finishedAt ?? DateTime.now()).difference(startedAt);

  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.volume);

  int get totalSetsDone => exercises.fold(0, (sum, e) => sum + e.completedSets);

  int get totalSetsPlanned => exercises
      .where((e) => !e.skipped)
      .fold(0, (sum, e) => sum + e.sets.length);

  double get progress =>
      totalSetsPlanned == 0 ? 0 : totalSetsDone / totalSetsPlanned;

  WorkoutSession copyWith({
    List<ExerciseLog>? exercises,
    int? currentIndex,
    DateTime? finishedAt,
  }) => WorkoutSession(
    id: id,
    dayTitle: dayTitle,
    dayFocus: dayFocus,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    exercises: exercises ?? this.exercises,
    currentIndex: currentIndex ?? this.currentIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayTitle': dayTitle,
    'dayFocus': dayFocus,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'currentIndex': currentIndex,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    dayTitle: json['dayTitle'] as String,
    dayFocus: json['dayFocus'] as String? ?? '',
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: json['finishedAt'] == null
        ? null
        : DateTime.tryParse(json['finishedAt'] as String),
    exercises: (json['exercises'] as List)
        .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
        .toList(),
    currentIndex: json['currentIndex'] as int? ?? 0,
  );
}
