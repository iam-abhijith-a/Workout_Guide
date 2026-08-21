import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/exercise.dart';

/// The exercise library, loaded once from the bundled asset.
///
/// 1,324 records parse in a few milliseconds, but doing it on the platform
/// thread still costs a visible frame on a cold start, so the decode runs in an
/// isolate and the splash covers it.
class ExerciseRepository {
  ExerciseRepository._(this.all)
    : _byId = {for (final e in all) e.id: e},
      bodyParts = _sortedUnique(all.map((e) => e.bodyPart)),
      equipmentNames = _sortedUnique(all.map((e) => e.equipment)),
      targets = _sortedUnique(all.map((e) => e.target));

  final List<Exercise> all;
  final Map<String, Exercise> _byId;

  /// Facet vocabularies, precomputed so filter sheets never scan the library.
  final List<String> bodyParts;
  final List<String> equipmentNames;
  final List<String> targets;

  /// Builds a repository from an already-decoded list.
  ///
  /// Exists for tests, which read the asset off disk directly rather than going
  /// through `rootBundle`.
  @visibleForTesting
  factory ExerciseRepository.fromExercises(List<Exercise> exercises) =>
      ExerciseRepository._(exercises);

  static Future<ExerciseRepository> load() async {
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final parsed = await compute(_parse, raw);
    return ExerciseRepository._(parsed);
  }

  static List<Exercise> _parse(String raw) => (jsonDecode(raw) as List)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  Exercise? byId(String id) => _byId[id];

  /// Resolves ids to exercises, dropping any that no longer exist so a stale
  /// saved plan degrades instead of crashing.
  List<Exercise> byIds(Iterable<String> ids) => [
    for (final id in ids)
      if (_byId[id] case final e?) e,
  ];

  static List<String> _sortedUnique(Iterable<String> values) =>
      values.toSet().toList()..sort();
}
