import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/exercise.dart';
import '../data/models/plan.dart';
import '../data/models/profile.dart';
import '../data/models/session.dart';
import '../data/plan/plan_generator.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/storage.dart';

/// Both of these are overridden with real instances in `main` once the async
/// bootstrap has finished, so nothing downstream has to handle a loading state.
final storageProvider = Provider<Storage>(
  (ref) => throw UnimplementedError('storageProvider must be overridden'),
);

final exerciseRepoProvider = Provider<ExerciseRepository>(
  (ref) => throw UnimplementedError('exerciseRepoProvider must be overridden'),
);

final planGeneratorProvider = Provider<PlanGenerator>(
  (ref) => PlanGenerator(ref.watch(exerciseRepoProvider).all),
);

// -- Profile ------------------------------------------------------------------

class ProfileController extends StateNotifier<Profile> {
  ProfileController(this._storage) : super(_storage.readProfile());

  final Storage _storage;

  void update(Profile Function(Profile) change) {
    state = change(state);
    _storage.writeProfile(state);
  }

  void reset() {
    state = const Profile();
    _storage.writeProfile(state);
  }
}

final profileProvider = StateNotifierProvider<ProfileController, Profile>(
  (ref) => ProfileController(ref.watch(storageProvider)),
);

// -- Plan ---------------------------------------------------------------------

class PlanController extends StateNotifier<Plan?> {
  PlanController(this._storage, this._generator) : super(_storage.readPlan());

  final Storage _storage;
  final PlanGenerator _generator;
  int _nonce = 0;

  Plan build(Profile profile) {
    final plan = _generator.generate(profile, nonce: _nonce);
    state = plan;
    _storage.writePlan(plan);
    return plan;
  }

  /// Same answers, different plan. The nonce is what stops "regenerate" from
  /// handing back the exact plan the user just rejected.
  Plan regenerate(Profile profile) {
    _nonce++;
    return build(profile);
  }

  void swapExercise(int dayIndex, int itemIndex, Exercise replacement) {
    final plan = state;
    if (plan == null) return;
    final day = plan.days[dayIndex];
    final items = [...day.items];
    items[itemIndex] = items[itemIndex].copyWith(
      exerciseId: replacement.id,
      note: replacement.unilateral ? 'Per side' : null,
    );
    final days = [...plan.days];
    days[dayIndex] = day.copyWith(items: items);
    state = Plan(
      name: plan.name,
      description: plan.description,
      days: days,
      generatedAt: plan.generatedAt,
    );
    _storage.writePlan(state!);
  }

  void clear() {
    state = null;
  }
}

final planProvider = StateNotifierProvider<PlanController, Plan?>(
  (ref) => PlanController(
    ref.watch(storageProvider),
    ref.watch(planGeneratorProvider),
  ),
);

// -- History ------------------------------------------------------------------

class HistoryController extends StateNotifier<List<WorkoutSession>> {
  HistoryController(this._storage) : super(_storage.readHistory());

  final Storage _storage;

  void add(WorkoutSession session) {
    state = [session, ...state];
    _storage.writeHistory(state);
  }

  void remove(String id) {
    state = state.where((s) => s.id != id).toList();
    _storage.writeHistory(state);
  }

  void clear() {
    state = const [];
    _storage.writeHistory(state);
  }
}

final historyProvider =
    StateNotifierProvider<HistoryController, List<WorkoutSession>>(
      (ref) => HistoryController(ref.watch(storageProvider)),
    );

/// Consecutive weeks in which at least one session was completed.
///
/// Deliberately measured in weeks, not days: a daily streak punishes exactly the
/// rest days a beginner needs, and the first missed day tends to end the habit.
final streakProvider = Provider<int>((ref) {
  final history = ref.watch(historyProvider);
  if (history.isEmpty) return 0;

  final weeks = <int>{for (final s in history) _weekKey(s.startedAt)};
  var streak = 0;
  var cursor = DateTime.now();

  // The current week only breaks the streak once it is over, so an empty
  // Monday does not wipe out three months of work.
  if (!weeks.contains(_weekKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 7));
    if (!weeks.contains(_weekKey(cursor))) return 0;
  }

  while (weeks.contains(_weekKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  return streak;
});

int _weekKey(DateTime date) {
  final monday = DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));
  return monday.year * 100 +
      (monday.difference(DateTime(monday.year)).inDays ~/ 7);
}

/// Sessions completed since Monday.
final sessionsThisWeekProvider = Provider<List<WorkoutSession>>((ref) {
  final history = ref.watch(historyProvider);
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  return history.where((s) => s.startedAt.isAfter(monday)).toList();
});

/// Which plan day to offer next.
///
/// Follows the plan's own order rather than the calendar. Someone who trains
/// Tuesday and Saturday should still get day 1 then day 2, not "whatever day
/// the week says it is".
final nextDayIndexProvider = Provider<int>((ref) {
  final plan = ref.watch(planProvider);
  if (plan == null || plan.days.isEmpty) return 0;
  final history = ref.watch(historyProvider);
  if (history.isEmpty) return 0;

  final last = history.first;
  final lastIndex = plan.days.indexWhere((d) => d.title == last.dayTitle);
  if (lastIndex == -1) return 0;
  return (lastIndex + 1) % plan.days.length;
});

// -- Favourites ---------------------------------------------------------------

class FavouritesController extends StateNotifier<Set<String>> {
  FavouritesController(this._storage) : super(_storage.readFavourites());

  final Storage _storage;

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    _storage.writeFavourites(state);
  }

  bool contains(String id) => state.contains(id);
}

final favouritesProvider =
    StateNotifierProvider<FavouritesController, Set<String>>(
      (ref) => FavouritesController(ref.watch(storageProvider)),
    );

// -- Last used weights --------------------------------------------------------

class LastWeightsController extends StateNotifier<Map<String, double>> {
  LastWeightsController(this._storage) : super(_storage.readLastWeights());

  final Storage _storage;

  void record(String exerciseId, double weight) {
    if (weight <= 0) return;
    state = {...state, exerciseId: weight};
    _storage.writeLastWeights(state);
  }

  double? forExercise(String id) => state[id];
}

final lastWeightsProvider =
    StateNotifierProvider<LastWeightsController, Map<String, double>>(
      (ref) => LastWeightsController(ref.watch(storageProvider)),
    );
