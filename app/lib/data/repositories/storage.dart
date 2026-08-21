import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/profile.dart';
import '../models/session.dart';

/// Local persistence. Everything the app knows lives on the device -- there is
/// no account and no network call anywhere in this app, which is what lets it
/// work in a basement gym with no signal.
class Storage {
  Storage(this._prefs);

  final SharedPreferences _prefs;

  static const _kProfile = 'forge.profile.v1';
  static const _kPlan = 'forge.plan.v1';
  static const _kHistory = 'forge.history.v1';
  static const _kActive = 'forge.active_session.v1';
  static const _kFavourites = 'forge.favourites.v1';
  static const _kLastWeights = 'forge.last_weights.v1';
  static const _kHomeKit = 'forge.home_kit.v1';

  static Future<Storage> open() async =>
      Storage(await SharedPreferences.getInstance());

  // -- Profile ---------------------------------------------------------------

  Profile readProfile() {
    final raw = _prefs.getString(_kProfile);
    if (raw == null) return const Profile();
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Profile();
    }
  }

  Future<void> writeProfile(Profile profile) =>
      _prefs.setString(_kProfile, jsonEncode(profile.toJson()));

  // -- Plan ------------------------------------------------------------------

  Plan? readPlan() {
    final raw = _prefs.getString(_kPlan);
    if (raw == null) return null;
    try {
      return Plan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writePlan(Plan plan) =>
      _prefs.setString(_kPlan, jsonEncode(plan.toJson()));

  // -- History ---------------------------------------------------------------

  List<WorkoutSession> readHistory() {
    final raw = _prefs.getStringList(_kHistory) ?? const [];
    final out = <WorkoutSession>[];
    for (final entry in raw) {
      try {
        out.add(
          WorkoutSession.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (_) {
        // A single corrupt entry should not cost the user their whole history.
      }
    }
    out.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return out;
  }

  Future<void> writeHistory(List<WorkoutSession> sessions) =>
      _prefs.setStringList(
        _kHistory,
        sessions.map((s) => jsonEncode(s.toJson())).toList(),
      );

  // -- Active session --------------------------------------------------------
  // Persisted on every change so a phone dying mid-workout does not lose the
  // sets already logged.

  WorkoutSession? readActiveSession() {
    final raw = _prefs.getString(_kActive);
    if (raw == null) return null;
    try {
      return WorkoutSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeActiveSession(WorkoutSession? session) async {
    if (session == null) {
      await _prefs.remove(_kActive);
    } else {
      await _prefs.setString(_kActive, jsonEncode(session.toJson()));
    }
  }

  // -- Favourites ------------------------------------------------------------

  Set<String> readFavourites() =>
      (_prefs.getStringList(_kFavourites) ?? const []).toSet();

  Future<void> writeFavourites(Set<String> ids) =>
      _prefs.setStringList(_kFavourites, ids.toList());

  // -- Last used weights -----------------------------------------------------
  // Prefilling the weight from last time is the difference between logging a set
  // in one tap and in six.

  Map<String, double> readLastWeights() {
    final raw = _prefs.getString(_kLastWeights);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> writeLastWeights(Map<String, double> weights) =>
      _prefs.setString(_kLastWeights, jsonEncode(weights));

  // -- Home kit --------------------------------------------------------------
  // What the user owns at home. Null means never answered, which is different
  // from "owns nothing" -- the first is a question to infer an answer to, the
  // second is an answer.

  Set<HomeGear>? readHomeKit() {
    final raw = _prefs.getStringList(_kHomeKit);
    if (raw == null) return null;
    return {
      for (final key in raw)
        if (HomeGear.fromKey(key) case final gear?) gear,
    };
  }

  Future<void> writeHomeKit(Set<HomeGear> kit) => _prefs.setStringList(
    _kHomeKit,
    kit.map((g) => g.storageKey).toList(),
  );

  Future<void> clearAll() async {
    for (final key in [
      _kProfile,
      _kPlan,
      _kHistory,
      _kActive,
      _kFavourites,
      _kLastWeights,
      _kHomeKit,
    ]) {
      await _prefs.remove(key);
    }
  }
}
