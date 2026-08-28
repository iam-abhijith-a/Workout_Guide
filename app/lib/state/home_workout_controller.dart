import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/exercise.dart';
import '../data/models/profile.dart';
import '../data/repositories/storage.dart';
import 'providers.dart';

/// How many cards a page of the grid holds.
///
/// Twenty is two columns by ten rows: long enough that paging is not constant,
/// short enough that the end of a page is reachable and the pager is a real
/// landmark rather than a thing you scroll past.
const kHomePageSize = 20;

/// A focus, named the way someone standing on a mat thinks about it.
///
/// Six of these are regions of the body. The last two cut across it -- a jump
/// squat is legs *and* conditioning, a hamstring stretch is legs *and*
/// mobility -- because at home those are the two sessions people actually ask
/// for by name, and burying them inside "Legs" would hide them.
enum HomeFocus {
  chest('Chest', 'Push-ups, presses and flyes'),
  back('Back', 'Pulls, rows and hangs'),
  shoulders('Shoulders', 'Presses and raises'),
  arms('Arms', 'Biceps, triceps and grip'),
  core('Core', 'Abs, obliques and lower back'),
  legs('Legs', 'Squats, hinges and calves'),
  conditioning('Conditioning', 'Heart rate up, no kit needed'),
  mobility('Mobility', 'Stretch out and loosen off');

  const HomeFocus(this.label, this.blurb);

  final String label;
  final String blurb;

  /// Body part *or* target muscle, because the dataset files a handstand
  /// push-up under "upper arms" and a pike push-up under the chest. Matching on
  /// one vocabulary alone leaves a focus missing the movements it is named for.
  bool matches(Exercise e) => switch (this) {
    chest => e.bodyPart == 'chest' || e.target == 'pectorals',
    back =>
      e.bodyPart == 'back' ||
          const {'lats', 'upper back', 'traps', 'spine'}.contains(e.target),
    // Neck work is two movements. It gets a home next to the shoulders rather
    // than a tile of its own that nobody would ever tap. Overhead pressing
    // comes in by pattern: a handstand push-up is shoulder work whatever the
    // dataset files it under.
    shoulders =>
      e.bodyPart == 'shoulders' ||
          e.bodyPart == 'neck' ||
          e.target == 'delts' ||
          e.pattern == MovementPattern.verticalPush,
    arms =>
      e.bodyPart == 'upper arms' ||
          e.bodyPart == 'lower arms' ||
          const {'biceps', 'triceps', 'forearms'}.contains(e.target),
    core =>
      e.bodyPart == 'waist' ||
          const {'abs', 'serratus anterior'}.contains(e.target),
    legs =>
      e.bodyPart == 'upper legs' ||
          e.bodyPart == 'lower legs' ||
          const {
            'quads',
            'hamstrings',
            'glutes',
            'calves',
            'adductors',
            'abductors',
          }.contains(e.target),
    conditioning =>
      e.pattern == MovementPattern.cardio || e.pattern == MovementPattern.plyo,
    mobility => e.pattern == MovementPattern.stretch,
  };
}

/// The kit filter, phrased as a requirement rather than as an inventory.
///
/// [none] is the one people reach for: "show me what I can do right now, on the
/// floor, holding nothing".
enum GearNeed {
  none('No kit at all'),
  dumbbell('Dumbbells'),
  pullUpBar('Pull-up bar'),
  bench('Bench or chair'),
  band('Band');

  const GearNeed(this.label);
  final String label;

  bool matches(Set<HomeGear> gear) => switch (this) {
    none => gear.isEmpty,
    dumbbell => gear.contains(HomeGear.dumbbell),
    pullUpBar => gear.contains(HomeGear.pullUpBar),
    bench => gear.contains(HomeGear.bench),
    band => gear.contains(HomeGear.band),
  };
}

enum HomeSort {
  /// Empty-handed work first, then the big movements, then the easiest version
  /// of each. The default, because someone who owns a band and asks for "legs
  /// at home" should not have to page past twenty band variations to find the
  /// squat -- which is exactly what ordering by compound-first produced.
  recommended('Recommended'),
  easiest('Easiest first'),
  hardest('Hardest first'),
  nameAsc('A to Z');

  const HomeSort(this.label);
  final String label;
}

@immutable
class HomeFilters {
  const HomeFilters({
    this.focus = HomeFocus.chest,
    this.difficulties = const {},
    this.gear = const {},
    this.patterns = const {},
    this.targets = const {},
    this.onlyFavourites = false,
    this.sort = HomeSort.recommended,
    this.page = 0,
  });

  final HomeFocus focus;
  final Set<Difficulty> difficulties;
  final Set<GearNeed> gear;
  final Set<MovementPattern> patterns;
  final Set<String> targets;
  final bool onlyFavourites;
  final HomeSort sort;
  final int page;

  int get activeCount =>
      difficulties.length +
      gear.length +
      patterns.length +
      targets.length +
      (onlyFavourites ? 1 : 0);

  HomeFilters copyWith({
    HomeFocus? focus,
    Set<Difficulty>? difficulties,
    Set<GearNeed>? gear,
    Set<MovementPattern>? patterns,
    Set<String>? targets,
    bool? onlyFavourites,
    HomeSort? sort,
    int? page,
  }) => HomeFilters(
    focus: focus ?? this.focus,
    difficulties: difficulties ?? this.difficulties,
    gear: gear ?? this.gear,
    patterns: patterns ?? this.patterns,
    targets: targets ?? this.targets,
    onlyFavourites: onlyFavourites ?? this.onlyFavourites,
    sort: sort ?? this.sort,
    page: page ?? this.page,
  );
}

/// What the user owns at home.
///
/// Stored separately from the gym equipment list in [Profile]: the answer to
/// "what is in this gym" and "what is in my flat" are different answers, and
/// conflating them is how someone with a gym membership ends up being shown
/// cable crossovers on a page about their living room.
class HomeKitController extends StateNotifier<Set<HomeGear>> {
  HomeKitController(this._storage, Profile profile)
    : super(_storage.readHomeKit() ?? _inferFrom(profile));

  final Storage _storage;

  void toggle(HomeGear gear) {
    state = state.contains(gear)
        ? ({...state}..remove(gear))
        : {...state, gear};
    _storage.writeHomeKit(state);
  }

  /// A first guess from onboarding, so the page is useful before anyone has
  /// touched it. Dumbbells and bands carry over; a pull-up bar and a bench are
  /// things the gym answer says nothing about, so they start off.
  static Set<HomeGear> _inferFrom(Profile profile) => {
    if (profile.equipment.contains(EquipClass.dumbbell)) HomeGear.dumbbell,
    if (profile.equipment.contains(EquipClass.band)) HomeGear.band,
  };
}

final homeKitProvider = StateNotifierProvider<HomeKitController, Set<HomeGear>>(
  // `read` rather than `watch` for the profile: this is a starting guess, and
  // rebuilding the controller when settings change would throw away a kit the
  // user had already corrected by hand.
  (ref) => HomeKitController(ref.watch(storageProvider), ref.read(profileProvider)),
);

/// Everything that can be done at home, with any kit at all. The ceiling, used
/// to say what one more piece of equipment would unlock.
final homeCatalogueProvider = Provider<List<Exercise>>(
  (ref) => [
    for (final e in ref.watch(exerciseRepoProvider).all)
      if (e.isHomeFriendly) e,
  ],
);

/// Everything doable with the kit the user actually has.
final homePoolProvider = Provider<List<Exercise>>((ref) {
  final kit = ref.watch(homeKitProvider);
  return [
    for (final e in ref.watch(homeCatalogueProvider))
      if (e.homeGear!.every(kit.contains)) e,
  ];
});

/// Per focus: how many movements are open now, and how many exist in total.
///
/// The gap between the two is the whole argument for owning a dumbbell, so it
/// is worth showing rather than hiding.
final homeFocusCountsProvider = Provider<Map<HomeFocus, ({int open, int all})>>((
  ref,
) {
  final pool = ref.watch(homePoolProvider);
  final catalogue = ref.watch(homeCatalogueProvider);
  return {
    for (final focus in HomeFocus.values)
      focus: (
        open: pool.where(focus.matches).length,
        all: catalogue.where(focus.matches).length,
      ),
  };
});

/// The one piece of kit that would open up the most in the focus being viewed.
///
/// Someone looking at four shoulder movements is not looking at a bug, they are
/// looking at the honest answer for an empty room -- but the useful thing to say
/// next is which single purchase changes that, and by how much.
final homeUnlockSuggestionProvider =
    Provider<({HomeGear gear, int count})?>((ref) {
      final kit = ref.watch(homeKitProvider);
      final focus = ref.watch(homeFiltersProvider).focus;
      final missing = HomeGear.values.where((g) => !kit.contains(g));
      if (missing.isEmpty) return null;

      final candidates = [
        for (final e in ref.watch(homeCatalogueProvider))
          if (focus.matches(e) && !e.homeGear!.every(kit.contains)) e,
      ];

      ({HomeGear gear, int count})? best;
      for (final gear in missing) {
        final unlocked = kit.union({gear});
        final count = candidates
            .where((e) => e.homeGear!.every(unlocked.contains))
            .length;
        if (count > 0 && (best == null || count > best.count)) {
          best = (gear: gear, count: count);
        }
      }
      return best;
    });

/// A few movements from a focus, for the preview thumbnails on its card.
///
/// Takes the easiest compounds first so the strip shows a push-up rather than
/// three variations of a decline flye.
List<Exercise> homeFocusPreview(List<Exercise> pool, HomeFocus focus, int n) {
  final matched = pool.where(focus.matches).toList()
    ..sort(_recommended);
  return matched.take(n).toList();
}

class HomeListController extends StateNotifier<HomeFilters> {
  HomeListController() : super(const HomeFilters());

  /// Opening a focus starts clean. Carrying "advanced only" from the chest page
  /// into the legs page would leave someone staring at an empty grid with no
  /// idea why.
  void open(HomeFocus focus) => state = HomeFilters(focus: focus);

  void setSort(HomeSort sort) => state = state.copyWith(sort: sort, page: 0);
  void setPage(int page) => state = state.copyWith(page: page);

  void toggleDifficulty(Difficulty v) => state = state.copyWith(
    difficulties: _toggle(state.difficulties, v),
    page: 0,
  );
  void toggleGear(GearNeed v) =>
      state = state.copyWith(gear: _toggle(state.gear, v), page: 0);
  void togglePattern(MovementPattern v) =>
      state = state.copyWith(patterns: _toggle(state.patterns, v), page: 0);
  void toggleTarget(String v) =>
      state = state.copyWith(targets: _toggle(state.targets, v), page: 0);
  void setOnlyFavourites(bool v) =>
      state = state.copyWith(onlyFavourites: v, page: 0);

  void clearFilters() =>
      state = HomeFilters(focus: state.focus, sort: state.sort);

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

final homeFiltersProvider =
    StateNotifierProvider<HomeListController, HomeFilters>(
      (ref) => HomeListController(),
    );

/// Everything in the open focus, before any facet is applied. The filter sheet
/// offers only the facets that exist here, so no option in it can ever lead to
/// an empty grid.
final homeFocusPoolProvider = Provider<List<Exercise>>((ref) {
  final focus = ref.watch(homeFiltersProvider).focus;
  return ref.watch(homePoolProvider).where(focus.matches).toList();
});

/// The filtered, sorted result set for the open focus.
final homeResultsProvider = Provider<List<Exercise>>((ref) {
  final f = ref.watch(homeFiltersProvider);
  final favourites = ref.watch(favouritesProvider);

  final matched = <Exercise>[];
  for (final e in ref.watch(homeFocusPoolProvider)) {
    if (f.difficulties.isNotEmpty && !f.difficulties.contains(e.difficulty)) {
      continue;
    }
    // Kit filters are an OR: ticking "no kit" and "dumbbells" means "either",
    // which is what someone deciding whether to pick the weights up wants.
    if (f.gear.isNotEmpty && !f.gear.any((g) => g.matches(e.homeGear!))) {
      continue;
    }
    if (f.patterns.isNotEmpty && !f.patterns.contains(e.pattern)) continue;
    if (f.targets.isNotEmpty && !f.targets.contains(e.target)) continue;
    if (f.onlyFavourites && !favourites.contains(e.id)) continue;
    matched.add(e);
  }

  matched.sort(switch (f.sort) {
    HomeSort.recommended => _recommended,
    HomeSort.easiest => (a, b) {
      final d = a.difficulty.index.compareTo(b.difficulty.index);
      return d != 0 ? d : a.name.compareTo(b.name);
    },
    HomeSort.hardest => (a, b) {
      final d = b.difficulty.index.compareTo(a.difficulty.index);
      return d != 0 ? d : a.name.compareTo(b.name);
    },
    HomeSort.nameAsc => (a, b) => a.name.compareTo(b.name),
  });

  return matched;
});

/// How many pages the current result set fills. Never zero, so "page 1 of 0"
/// cannot happen on an empty grid.
final homePageCountProvider = Provider<int>((ref) {
  final count = ref.watch(homeResultsProvider).length;
  return count == 0 ? 1 : ((count - 1) ~/ kHomePageSize) + 1;
});

/// The slice of results on the current page.
final homePageProvider = Provider<List<Exercise>>((ref) {
  final results = ref.watch(homeResultsProvider);
  // Clamped rather than trusted: a filter that shrinks the set while the user
  // sits on page 6 must land them on the last real page, not on nothing.
  final page = ref
      .watch(homeFiltersProvider)
      .page
      .clamp(0, ref.watch(homePageCountProvider) - 1);
  final start = page * kHomePageSize;
  if (start >= results.length) return const [];
  final end = start + kHomePageSize;
  return results.sublist(start, end > results.length ? results.length : end);
});

/// Least kit first, then the big movements, then the easiest version of each.
///
/// Kit leads deliberately. On a page about a living room, "what can I do
/// holding nothing" outranks "what is the biggest lift", and putting compound
/// first meant a band owner's first two pages were band variations.
int _recommended(Exercise a, Exercise b) {
  final k = a.homeGear!.length.compareTo(b.homeGear!.length);
  if (k != 0) return k;
  if (a.compound != b.compound) return a.compound ? -1 : 1;
  final d = a.difficulty.index.compareTo(b.difficulty.index);
  if (d != 0) return d;
  return a.name.compareTo(b.name);
}
