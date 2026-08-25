import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/exercise.dart';
import '../data/models/plan.dart';
import '../data/models/session.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/storage.dart';
import 'providers.dart';

/// The rest countdown.
///
/// Kept as its own object rather than living in the session state because it
/// ticks every second, and rebuilding the whole workout screen once a second to
/// move a number would be wasteful.
class RestTimerState {
  const RestTimerState({
    this.total = 0,
    this.remaining = 0,
    this.running = false,
    this.exerciseId,
  });

  final int total;
  final int remaining;
  final bool running;
  final String? exerciseId;

  bool get isActive => running && remaining > 0;
  double get progress => total == 0 ? 0 : (total - remaining) / total;

  RestTimerState copyWith({
    int? total,
    int? remaining,
    bool? running,
    String? exerciseId,
  }) => RestTimerState(
    total: total ?? this.total,
    remaining: remaining ?? this.remaining,
    running: running ?? this.running,
    exerciseId: exerciseId ?? this.exerciseId,
  );
}

class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController() : super(const RestTimerState());

  Timer? _ticker;

  void start(int seconds, {String? exerciseId}) {
    if (seconds <= 0) return;
    _ticker?.cancel();
    state = RestTimerState(
      total: seconds,
      remaining: seconds,
      running: true,
      exerciseId: exerciseId,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final next = state.remaining - 1;
    if (next <= 0) {
      _ticker?.cancel();
      state = state.copyWith(remaining: 0, running: false);
      // Rest ending is the one moment the user is not looking at the screen,
      // so it gets a haptic rather than a visual cue alone.
      HapticFeedback.heavyImpact();
    } else {
      state = state.copyWith(remaining: next);
      // A soft tick over the last three seconds, so the finish is not a surprise.
      if (next <= 3) HapticFeedback.selectionClick();
    }
  }

  void add(int seconds) {
    if (!state.running) return;
    state = state.copyWith(
      remaining: state.remaining + seconds,
      total: state.total + seconds,
    );
  }

  void skip() {
    _ticker?.cancel();
    state = const RestTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerController, RestTimerState>(
      (ref) => RestTimerController(),
    );

/// Drives a workout from start to finish.
class SessionController extends StateNotifier<WorkoutSession?> {
  SessionController(this._ref, this._storage, this._repo)
    : super(_storage.readActiveSession());

  final Ref _ref;
  final Storage _storage;
  final ExerciseRepository _repo;

  /// Turns a plan day into a live session, seeding each set with the weight used
  /// last time so most sets can be logged in a single tap.
  void start(PlanDay day) {
    final lastWeights = _ref.read(lastWeightsProvider);
    final logs = <ExerciseLog>[];

    for (final item in day.items) {
      final exercise = _repo.byId(item.exerciseId);
      if (exercise == null) continue;
      logs.add(
        ExerciseLog(
          exerciseId: item.exerciseId,
          name: exercise.name,
          role: item.role,
          restSeconds: item.restSeconds,
          sets: List.generate(
            item.sets,
            (_) => SetLog(
              targetReps: item.repHigh,
              weight: lastWeights[item.exerciseId],
            ),
          ),
        ),
      );
    }

    final session = WorkoutSession(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      dayTitle: day.title,
      dayFocus: day.focus,
      startedAt: DateTime.now(),
      exercises: logs,
    );
    _persist(session);
  }

  void completeSet(
    int exerciseIndex,
    int setIndex, {
    int? reps,
    double? weight,
  }) {
    final session = state;
    if (session == null) return;

    final exercises = [...session.exercises];
    final log = exercises[exerciseIndex];
    final sets = [...log.sets];
    final target = sets[setIndex];

    sets[setIndex] = target.copyWith(
      done: true,
      reps: reps ?? target.reps ?? target.targetReps,
      weight: weight ?? target.weight,
    );
    exercises[exerciseIndex] = log.copyWith(sets: sets);

    final finalWeight = weight ?? target.weight;
    if (finalWeight != null) {
      _ref
          .read(lastWeightsProvider.notifier)
          .record(log.exerciseId, finalWeight);
    }

    _persist(session.copyWith(exercises: exercises));
    HapticFeedback.mediumImpact();

    // Rest starts on its own after a working set. Making the user press "start
    // rest" is asking them to do the app's job while out of breath.
    final restEnabled = _ref.read(profileProvider).restTimerEnabled;
    final moreSetsHere = sets.any((s) => !s.done);
    if (restEnabled && log.restSeconds > 0 && moreSetsHere) {
      _ref
          .read(restTimerProvider.notifier)
          .start(log.restSeconds, exerciseId: log.exerciseId);
    }
  }

  void uncompleteSet(int exerciseIndex, int setIndex) {
    final session = state;
    if (session == null) return;
    final exercises = [...session.exercises];
    final log = exercises[exerciseIndex];
    final sets = [...log.sets];
    sets[setIndex] = SetLog(
      targetReps: sets[setIndex].targetReps,
      reps: sets[setIndex].reps,
      weight: sets[setIndex].weight,
    );
    exercises[exerciseIndex] = log.copyWith(sets: sets);
    _persist(session.copyWith(exercises: exercises));
  }

  void updateSet(int exerciseIndex, int setIndex, {int? reps, double? weight}) {
    final session = state;
    if (session == null) return;
    final exercises = [...session.exercises];
    final log = exercises[exerciseIndex];
    final sets = [...log.sets];
    sets[setIndex] = sets[setIndex].copyWith(reps: reps, weight: weight);
    exercises[exerciseIndex] = log.copyWith(sets: sets);
    _persist(session.copyWith(exercises: exercises));
  }

  /// An extra set beyond the plan. Cheap to allow, and it stops the app feeling
  /// like it is arguing with someone who feels good today.
  void addSet(int exerciseIndex) {
    final session = state;
    if (session == null) return;
    final exercises = [...session.exercises];
    final log = exercises[exerciseIndex];
    final last = log.sets.isEmpty ? null : log.sets.last;
    exercises[exerciseIndex] = log.copyWith(
      sets: [
        ...log.sets,
        SetLog(targetReps: last?.targetReps ?? 10, weight: last?.weight),
      ],
    );
    _persist(session.copyWith(exercises: exercises));
  }

  void removeSet(int exerciseIndex) {
    final session = state;
    if (session == null) return;
    final exercises = [...session.exercises];
    final log = exercises[exerciseIndex];
    if (log.sets.length <= 1) return;
    exercises[exerciseIndex] = log.copyWith(
      sets: log.sets.sublist(0, log.sets.length - 1),
    );
    _persist(session.copyWith(exercises: exercises));
  }

  void skipExercise(int exerciseIndex) {
    final session = state;
    if (session == null) return;
    final exercises = [...session.exercises];
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      skipped: !exercises[exerciseIndex].skipped,
    );
    _persist(session.copyWith(exercises: exercises));
  }

  /// Replaces an exercise mid-session, keeping the set structure. This is the
  /// "someone is on the machine" escape hatch.
  void swapExercise(int exerciseIndex, Exercise replacement) {
    final session = state;
    if (session == null) return;
    final exercises = [...session.exercises];
    final old = exercises[exerciseIndex];
    exercises[exerciseIndex] = ExerciseLog(
      exerciseId: replacement.id,
      name: replacement.name,
      role: old.role,
      restSeconds: old.restSeconds,
      sets: old.sets.map((s) => SetLog(targetReps: s.targetReps)).toList(),
    );
    _persist(session.copyWith(exercises: exercises));
  }

  void goTo(int index) {
    final session = state;
    if (session == null) return;
    if (index < 0 || index >= session.exercises.length) return;
    _persist(session.copyWith(currentIndex: index));
  }

  /// Ends the workout and moves it into history. Returns the finished session so
  /// the summary screen can show it without another read.
  WorkoutSession? finish() {
    final session = state;
    if (session == null) return null;
    final finished = session.copyWith(finishedAt: DateTime.now());
    _ref.read(historyProvider.notifier).add(finished);
    _ref.read(restTimerProvider.notifier).skip();
    state = null;
    _storage.writeActiveSession(null);
    return finished;
  }

  /// Abandons without recording. Used for "I opened this by accident".
  void discard() {
    _ref.read(restTimerProvider.notifier).skip();
    state = null;
    _storage.writeActiveSession(null);
  }

  void _persist(WorkoutSession session) {
    state = session;
    // Written on every mutation: a workout is 45 minutes of input the user
    // cannot reconstruct, and phones die.
    unawaited(_storage.writeActiveSession(session));
  }
}

final sessionProvider =
    StateNotifierProvider<SessionController, WorkoutSession?>(
      (ref) => SessionController(
        ref,
        ref.watch(storageProvider),
        ref.watch(exerciseRepoProvider),
      ),
    );

/// Index of the exercise the user should be looking at.
///
/// Falls forward to the first unfinished exercise, so coming back to a session
/// lands you where you left off rather than at the top.
final activeExerciseIndexProvider = Provider<int>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return 0;
  final current = session.currentIndex;
  if (current < session.exercises.length &&
      !session.exercises[current].isComplete &&
      !session.exercises[current].skipped) {
    return current;
  }
  final next = session.exercises.indexWhere((e) => !e.isComplete && !e.skipped);
  return next == -1 ? session.exercises.length - 1 : next;
});

@immutable
class ProgressStats {
  const ProgressStats({
    required this.totalSessions,
    required this.totalVolume,
    required this.totalSets,
    required this.totalMinutes,
    required this.volumeByWeek,
    required this.setsByBodyPart,
  });

  final int totalSessions;
  final double totalVolume;
  final int totalSets;
  final int totalMinutes;

  /// Oldest to newest, one entry per week that had a session.
  final List<({DateTime week, double volume})> volumeByWeek;
  final Map<String, int> setsByBodyPart;
}

/// Aggregates history into the numbers the progress screen shows.
final progressStatsProvider = Provider<ProgressStats>((ref) {
  final history = ref.watch(historyProvider);
  final repo = ref.watch(exerciseRepoProvider);

  var volume = 0.0;
  var sets = 0;
  var minutes = 0;
  final byWeek = <DateTime, double>{};
  final byBodyPart = <String, int>{};

  for (final session in history) {
    volume += session.totalVolume;
    sets += session.totalSetsDone;
    minutes += session.duration.inMinutes;

    final d = session.startedAt;
    final monday = DateTime(
      d.year,
      d.month,
      d.day,
    ).subtract(Duration(days: d.weekday - 1));
    byWeek[monday] = (byWeek[monday] ?? 0) + session.totalVolume;

    for (final log in session.exercises) {
      if (log.role == PlanRole.warmup || log.role == PlanRole.cooldown) {
        continue;
      }
      final exercise = repo.byId(log.exerciseId);
      if (exercise == null) continue;
      byBodyPart[exercise.bodyPart] =
          (byBodyPart[exercise.bodyPart] ?? 0) + log.completedSets;
    }
  }

  final weeks =
      byWeek.entries.map((e) => (week: e.key, volume: e.value)).toList()
        ..sort((a, b) => a.week.compareTo(b.week));

  return ProgressStats(
    totalSessions: history.length,
    totalVolume: volume,
    totalSets: sets,
    totalMinutes: minutes,
    volumeByWeek: weeks,
    setsByBodyPart: byBodyPart,
  );
});
