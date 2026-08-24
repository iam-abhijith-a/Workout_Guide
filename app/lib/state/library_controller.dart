import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/exercise.dart';
import 'providers.dart';

enum LibrarySort {
  relevance('Best match'),
  nameAsc('A to Z'),
  easiest('Easiest first'),
  hardest('Hardest first');

  const LibrarySort(this.label);
  final String label;
}

@immutable
class LibraryFilters {
  const LibraryFilters({
    this.query = '',
    this.bodyParts = const {},
    this.equipment = const {},
    this.targets = const {},
    this.difficulties = const {},
    this.patterns = const {},
    this.onlyMyEquipment = false,
    this.onlyFavourites = false,
    this.sort = LibrarySort.relevance,
  });

  final String query;
  final Set<String> bodyParts;
  final Set<EquipClass> equipment;
  final Set<String> targets;
  final Set<Difficulty> difficulties;
  final Set<MovementPattern> patterns;

  /// "Only show me things I can actually do today." The single most useful
  /// filter in the app and the reason it gets its own toggle rather than being
  /// buried in the equipment list.
  final bool onlyMyEquipment;
  final bool onlyFavourites;
  final LibrarySort sort;

  int get activeCount =>
      bodyParts.length +
      equipment.length +
      targets.length +
      difficulties.length +
      patterns.length +
      (onlyMyEquipment ? 1 : 0) +
      (onlyFavourites ? 1 : 0);

  bool get isEmpty => activeCount == 0 && query.isEmpty;

  LibraryFilters copyWith({
    String? query,
    Set<String>? bodyParts,
    Set<EquipClass>? equipment,
    Set<String>? targets,
    Set<Difficulty>? difficulties,
    Set<MovementPattern>? patterns,
    bool? onlyMyEquipment,
    bool? onlyFavourites,
    LibrarySort? sort,
  }) => LibraryFilters(
    query: query ?? this.query,
    bodyParts: bodyParts ?? this.bodyParts,
    equipment: equipment ?? this.equipment,
    targets: targets ?? this.targets,
    difficulties: difficulties ?? this.difficulties,
    patterns: patterns ?? this.patterns,
    onlyMyEquipment: onlyMyEquipment ?? this.onlyMyEquipment,
    onlyFavourites: onlyFavourites ?? this.onlyFavourites,
    sort: sort ?? this.sort,
  );
}

class LibraryController extends StateNotifier<LibraryFilters> {
  LibraryController() : super(const LibraryFilters());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setSort(LibrarySort sort) => state = state.copyWith(sort: sort);

  void toggleBodyPart(String v) =>
      state = state.copyWith(bodyParts: _toggle(state.bodyParts, v));
  void toggleTarget(String v) =>
      state = state.copyWith(targets: _toggle(state.targets, v));
  void toggleEquipment(EquipClass v) =>
      state = state.copyWith(equipment: _toggle(state.equipment, v));
  void toggleDifficulty(Difficulty v) =>
      state = state.copyWith(difficulties: _toggle(state.difficulties, v));
  void togglePattern(MovementPattern v) =>
      state = state.copyWith(patterns: _toggle(state.patterns, v));

  void setOnlyMyEquipment(bool v) => state = state.copyWith(onlyMyEquipment: v);
  void setOnlyFavourites(bool v) => state = state.copyWith(onlyFavourites: v);

  /// Clears facets but keeps the query -- a user clearing filters is refining a
  /// search, not abandoning it.
  void clearFilters() =>
      state = LibraryFilters(query: state.query, sort: state.sort);

  void clearAll() => state = const LibraryFilters();

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

final libraryFiltersProvider =
    StateNotifierProvider<LibraryController, LibraryFilters>(
      (ref) => LibraryController(),
    );

/// The filtered, sorted result set.
///
/// Runs synchronously over 1,324 records on every keystroke. That is fast enough
/// to stay well inside a frame, and it keeps search feeling instant -- which
/// matters more here than any amount of indexing cleverness.
final libraryResultsProvider = Provider<List<Exercise>>((ref) {
  final all = ref.watch(exerciseRepoProvider).all;
  final f = ref.watch(libraryFiltersProvider);
  final favourites = ref.watch(favouritesProvider);
  final profile = ref.watch(profileProvider);

  final terms = f.query
      .toLowerCase()
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();

  final matched = <Exercise>[];
  for (final e in all) {
    if (f.bodyParts.isNotEmpty && !f.bodyParts.contains(e.bodyPart)) continue;
    if (f.targets.isNotEmpty && !f.targets.contains(e.target)) continue;
    if (f.equipment.isNotEmpty && !f.equipment.contains(e.equipClass)) continue;
    if (f.difficulties.isNotEmpty && !f.difficulties.contains(e.difficulty)) {
      continue;
    }
    if (f.patterns.isNotEmpty && !f.patterns.contains(e.pattern)) continue;
    if (f.onlyMyEquipment && !profile.equipment.contains(e.equipClass)) {
      continue;
    }
    if (f.onlyFavourites && !favourites.contains(e.id)) continue;

    // Every term must appear somewhere, so "dumbbell chest" narrows rather than
    // widening the way a plain OR search would.
    if (terms.isNotEmpty && !terms.every(e.searchIndex.contains)) continue;

    matched.add(e);
  }

  int relevance(Exercise e) {
    if (terms.isEmpty) return 0;
    final name = e.name.toLowerCase();
    var score = 0;
    // A name match beats a match buried in the muscle list, and a name that
    // *starts* with the query beats one that merely contains it.
    if (terms.every(name.contains)) score -= 40;
    if (name.startsWith(terms.first)) score -= 30;
    score += name.length; // shorter, more canonical names first
    return score;
  }

  matched.sort(switch (f.sort) {
    LibrarySort.relevance => (a, b) {
      final r = relevance(a).compareTo(relevance(b));
      return r != 0 ? r : a.name.compareTo(b.name);
    },
    LibrarySort.nameAsc => (a, b) => a.name.compareTo(b.name),
    LibrarySort.easiest => (a, b) {
      final d = a.difficulty.index.compareTo(b.difficulty.index);
      return d != 0 ? d : a.name.compareTo(b.name);
    },
    LibrarySort.hardest => (a, b) {
      final d = b.difficulty.index.compareTo(a.difficulty.index);
      return d != 0 ? d : a.name.compareTo(b.name);
    },
  });

  return matched;
});
