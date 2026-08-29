import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_guide/data/models/exercise.dart';
import 'package:workout_guide/data/models/profile.dart';
import 'package:workout_guide/data/repositories/exercise_repository.dart';
import 'package:workout_guide/data/repositories/storage.dart';
import 'package:workout_guide/state/home_workout_controller.dart';
import 'package:workout_guide/state/providers.dart';
import 'package:workout_guide/ui/screens/home_workout/focus_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

/// The guarantees the home page rests on.
///
/// The page makes one promise -- everything on it can be done in your living
/// room with the kit you ticked -- and these are the checks that the promise
/// survives the data, the filters, the sort and the pager.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseRepository repo;

  setUpAll(() {
    repo = ExerciseRepository.fromExercises(loadLibrary());
  });

  Future<ProviderContainer> harness({
    Set<EquipClass> equipment = const {EquipClass.bodyweight},
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    await storage.writeProfile(Profile(equipment: equipment, onboarded: true));
    return ProviderContainer(
      overrides: [
        storageProvider.overrideWithValue(storage),
        exerciseRepoProvider.overrideWithValue(repo),
      ],
    );
  }

  group('the home catalogue', () {
    test('is a real subset, and every entry declares what it needs', () {
      final home = repo.all.where((e) => e.isHomeFriendly).toList();

      expect(home.length, greaterThan(500));
      expect(home.length, lessThan(repo.all.length));
      for (final e in home) {
        expect(e.homeGear, isNotNull);
      }
      // The case the page exists for: things needing nothing at all.
      expect(home.where((e) => e.homeGear!.isEmpty).length, greaterThan(150));
    });

    test('leaves the gym in the gym', () {
      for (final e in repo.all) {
        if (!e.isHomeFriendly) continue;
        expect(
          e.equipClass,
          isNot(
            anyOf(
              EquipClass.barbell,
              EquipClass.cable,
              EquipClass.machine,
              EquipClass.kettlebell,
              EquipClass.cardioMachine,
            ),
          ),
          reason: '${e.name} is not something you own',
        );
      }
    });
  });

  group('the kit', () {
    test('starts from what onboarding already asked about', () async {
      final container = await harness(
        equipment: {EquipClass.bodyweight, EquipClass.dumbbell},
      );
      addTearDown(container.dispose);

      expect(container.read(homeKitProvider), contains(HomeGear.dumbbell));
    });

    test('decides the pool, and nothing in the pool needs more', () async {
      final container = await harness();
      addTearDown(container.dispose);

      final barefoot = container.read(homePoolProvider);
      expect(barefoot, isNotEmpty);
      for (final e in barefoot) {
        expect(e.homeGear, isEmpty, reason: '${e.name} needs kit');
      }

      container.read(homeKitProvider.notifier).toggle(HomeGear.pullUpBar);
      final withBar = container.read(homePoolProvider);

      expect(withBar.length, greaterThan(barefoot.length));
      for (final e in withBar) {
        expect(e.homeGear!.every({HomeGear.pullUpBar}.contains), isTrue);
      }
      // Pull-ups are the entire reason someone screws a bar into a doorway.
      expect(withBar.any((e) => e.name == 'Pull-Up'), isTrue);
    });

    test('survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await Storage.open();
      await storage.writeProfile(const Profile(onboarded: true));

      final first = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(storage),
          exerciseRepoProvider.overrideWithValue(repo),
        ],
      );
      first.read(homeKitProvider.notifier).toggle(HomeGear.bench);
      first.dispose();

      final second = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(storage),
          exerciseRepoProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(second.dispose);
      expect(second.read(homeKitProvider), {HomeGear.bench});
    });
  });

  group('a focus', () {
    test('has something in it for every focus, with the full kit', () async {
      final container = await harness();
      addTearDown(container.dispose);
      for (final gear in HomeGear.values) {
        container.read(homeKitProvider.notifier).toggle(gear);
      }

      final counts = container.read(homeFocusCountsProvider);
      for (final focus in HomeFocus.values) {
        expect(
          counts[focus]!.open,
          greaterThanOrEqualTo(10),
          reason: '${focus.label} is too thin to be a tile',
        );
      }
    });

    test('never claims more is open than exists', () async {
      final container = await harness();
      addTearDown(container.dispose);

      for (final entry in container.read(homeFocusCountsProvider).entries) {
        expect(entry.value.open, lessThanOrEqualTo(entry.value.all));
      }
    });

    test('shows only its own movements', () async {
      final container = await harness();
      addTearDown(container.dispose);
      container.read(homeFiltersProvider.notifier).open(HomeFocus.core);

      final results = container.read(homeResultsProvider);
      expect(results, isNotEmpty);
      for (final e in results) {
        expect(HomeFocus.core.matches(e), isTrue);
      }
    });
  });

  group('filters and sort', () {
    test('kit filters read as "either", not "both"', () async {
      final container = await harness();
      addTearDown(container.dispose);
      container.read(homeKitProvider.notifier).toggle(HomeGear.dumbbell);
      final filters = container.read(homeFiltersProvider.notifier)
        ..open(HomeFocus.arms)
        ..toggleGear(GearNeed.none)
        ..toggleGear(GearNeed.dumbbell);

      final results = container.read(homeResultsProvider);
      expect(results.any((e) => e.homeGear!.isEmpty), isTrue);
      expect(
        results.any((e) => e.homeGear!.contains(HomeGear.dumbbell)),
        isTrue,
      );

      filters.clearFilters();
      expect(container.read(homeFiltersProvider).activeCount, 0);
    });

    test('difficulty narrows and nothing else leaks in', () async {
      final container = await harness();
      addTearDown(container.dispose);
      final filters = container.read(homeFiltersProvider.notifier)
        ..open(HomeFocus.legs);

      final all = container.read(homeResultsProvider).length;
      filters.toggleDifficulty(Difficulty.beginner);
      final beginner = container.read(homeResultsProvider);

      expect(beginner.length, lessThan(all));
      for (final e in beginner) {
        expect(e.difficulty, Difficulty.beginner);
      }
    });

    test('recommended puts the big, simple movements first', () async {
      final container = await harness();
      addTearDown(container.dispose);
      container.read(homeFiltersProvider.notifier).open(HomeFocus.chest);

      final results = container.read(homeResultsProvider);
      expect(results.first.compound, isTrue);
      expect(results.first.difficulty, Difficulty.beginner);
    });

    test('recommended leads with what needs no kit', () async {
      final container = await harness();
      addTearDown(container.dispose);
      for (final gear in HomeGear.values) {
        container.read(homeKitProvider.notifier).toggle(gear);
      }
      container.read(homeFiltersProvider.notifier).open(HomeFocus.legs);

      final results = container.read(homeResultsProvider);
      expect(results.first.homeGear, isEmpty);
      // Monotonic: the amount of kit only ever goes up as you read down, so a
      // band owner's first page is never twenty band variations.
      var previous = 0;
      for (final e in results) {
        expect(e.homeGear!.length, greaterThanOrEqualTo(previous));
        previous = e.homeGear!.length;
      }
      // And the whole first page is reachable empty-handed.
      for (final e in container.read(homePageProvider)) {
        expect(e.homeGear, isEmpty);
      }
    });
  });

  group('paging', () {
    test('cuts the results into pages of twenty', () async {
      final container = await harness();
      addTearDown(container.dispose);
      for (final gear in HomeGear.values) {
        container.read(homeKitProvider.notifier).toggle(gear);
      }
      final filters = container.read(homeFiltersProvider.notifier)
        ..open(HomeFocus.arms);

      final total = container.read(homeResultsProvider).length;
      expect(total, greaterThan(kHomePageSize));
      expect(
        container.read(homePageCountProvider),
        ((total - 1) ~/ kHomePageSize) + 1,
      );
      expect(container.read(homePageProvider).length, kHomePageSize);

      // No page repeats a movement, and together they are the whole set.
      final seen = <String>{};
      for (var p = 0; p < container.read(homePageCountProvider); p++) {
        filters.setPage(p);
        for (final e in container.read(homePageProvider)) {
          expect(seen.add(e.id), isTrue, reason: '${e.name} appears twice');
        }
      }
      expect(seen.length, total);
    });

    test('a filter applied on page 6 does not strand you there', () async {
      final container = await harness();
      addTearDown(container.dispose);
      final filters = container.read(homeFiltersProvider.notifier)
        ..open(HomeFocus.core)
        ..setPage(3);

      expect(container.read(homePageProvider), isNotEmpty);

      // Something that leaves a single page's worth behind.
      filters.toggleDifficulty(Difficulty.advanced);
      expect(container.read(homeFiltersProvider).page, 0);
      expect(container.read(homePageProvider), isNotEmpty);
    });

    test('an empty result set is still one page, not zero', () async {
      final container = await harness();
      addTearDown(container.dispose);
      container.read(homeFiltersProvider.notifier)
        ..open(HomeFocus.mobility)
        ..setOnlyFavourites(true);

      expect(container.read(homeResultsProvider), isEmpty);
      expect(container.read(homePageCountProvider), 1);
      expect(container.read(homePageProvider), isEmpty);
    });
  });

  group('the unlock nudge', () {
    test('names the kit that would open up the most, and only real gaps', () async {
      final container = await harness();
      addTearDown(container.dispose);
      container.read(homeFiltersProvider.notifier).open(HomeFocus.shoulders);

      // An empty room is a thin shoulder day, and dumbbells are the fix.
      final suggestion = container.read(homeUnlockSuggestionProvider);
      expect(suggestion, isNotNull);
      expect(suggestion!.gear, HomeGear.dumbbell);
      expect(suggestion.count, greaterThan(20));

      // Taking the suggestion has to actually deliver what it promised.
      final before = container.read(homeResultsProvider).length;
      container.read(homeKitProvider.notifier).toggle(HomeGear.dumbbell);
      expect(
        container.read(homeResultsProvider).length,
        before + suggestion.count,
      );

      for (final gear in HomeGear.values) {
        if (!container.read(homeKitProvider).contains(gear)) {
          container.read(homeKitProvider.notifier).toggle(gear);
        }
      }
      // Nothing left to suggest once you own everything.
      expect(container.read(homeUnlockSuggestionProvider), isNull);
    });
  });

  group('the focus screen', () {
    testWidgets('renders a grid and turns the page', (tester) async {
      final container = await harness(
        equipment: {EquipClass.bodyweight, EquipClass.dumbbell},
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        wrap(container, const FocusScreen(focus: HomeFocus.legs)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Legs'), findsOneWidget);
      expect(container.read(homeFiltersProvider).focus, HomeFocus.legs);
      expect(tester.takeException(), isNull);

      // The pager sits under twenty cards, which is the whole point of it.
      await tester.scrollUntilVisible(
        find.text('2'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(seconds: 1));

      expect(container.read(homeFiltersProvider).page, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
