import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_guide/data/models/exercise.dart';
import 'package:workout_guide/data/models/profile.dart';
import 'package:workout_guide/data/repositories/exercise_repository.dart';
import 'package:workout_guide/data/repositories/storage.dart';
import 'package:workout_guide/state/library_controller.dart';
import 'package:workout_guide/state/providers.dart';
import 'package:workout_guide/state/session_controller.dart';
import 'package:workout_guide/state/home_workout_controller.dart';
import 'package:workout_guide/ui/screens/home_workout/home_workout_screen.dart';
import 'package:workout_guide/ui/screens/learn/learn_screen.dart';
import 'package:workout_guide/ui/screens/library/exercise_detail_screen.dart';
import 'package:workout_guide/ui/screens/library/library_screen.dart';
import 'package:workout_guide/ui/screens/plan/plan_screen.dart';
import 'package:workout_guide/ui/screens/progress/progress_screen.dart';
import 'package:workout_guide/ui/screens/root_screen.dart';
import 'package:workout_guide/ui/screens/session/session_screen.dart';
import 'package:workout_guide/ui/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

/// Every screen in the app, driven with the real library and real state.
///
/// `flutter analyze` proves the code compiles; it proves nothing about whether a
/// screen throws on its first frame. These tests actually pump each surface and
/// walk the flow a new user takes, which is the only way to catch a layout
/// overflow or a null the analyser is happy with.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseRepository repo;

  setUpAll(() async {
    repo = ExerciseRepository.fromExercises(loadLibrary());
  });

  Future<ProviderContainer> harness({Profile? profile}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    if (profile != null) await storage.writeProfile(profile);

    return ProviderContainer(
      overrides: [
        storageProvider.overrideWithValue(storage),
        exerciseRepoProvider.overrideWithValue(repo),
      ],
    );
  }

  const onboardedProfile = Profile(
    name: 'Sam',
    goal: Goal.muscle,
    experience: Experience.never,
    daysPerWeek: 3,
    equipment: {
      EquipClass.bodyweight,
      EquipClass.dumbbell,
      EquipClass.machine,
      EquipClass.cable,
      EquipClass.cardioMachine,
    },
    onboarded: true,
  );

  group('screens render', () {
    testWidgets('at home, with every focus counted', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container, const HomeWorkoutScreen()));
      await tester.pump(const Duration(seconds: 1));

      // Tiles are built lazily, so the later ones have to be scrolled to --
      // which is also the check that the grid scrolls at all.
      for (final focus in HomeFocus.values) {
        await tester.scrollUntilVisible(
          find.text(focus.label),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text(focus.label),
          findsWidgets,
          reason: '${focus.label} is missing a tile',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('plan, showing the week and a resumable session', (
      tester,
    ) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);
      final plan = container
          .read(planProvider.notifier)
          .build(onboardedProfile);
      container.read(sessionProvider.notifier).start(plan.days.first);

      await tester.pumpWidget(wrap(container, const PlanScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Resume workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('plan', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);
      final plan = container
          .read(planProvider.notifier)
          .build(onboardedProfile);

      await tester.pumpWidget(wrap(container, const PlanScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(plan.days.first.title), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('library, and it filters as you type', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container, const LibraryScreen()));
      await tester.pump(const Duration(seconds: 1));

      final all = container.read(exerciseRepoProvider).all.length;
      expect(all, 1324);

      container
          .read(libraryFiltersProvider.notifier)
          .setQuery('dumbbell bench');
      await tester.pump(const Duration(seconds: 1));

      final filtered = container.read(libraryResultsProvider);
      expect(filtered.length, lessThan(all));
      expect(filtered, isNotEmpty);
      // Every term has to appear, so this is a narrowing search, not a widening one.
      for (final e in filtered) {
        expect(e.searchIndex, contains('dumbbell'));
        expect(e.searchIndex, contains('bench'));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('progress, when nothing has been logged', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container, const ProgressScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('learn', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container, const LearnScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Your very first session'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container, const SettingsScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('Build muscle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exercise detail renders for a spread of the library', (
      tester,
    ) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      // One exercise from each pattern, so every coaching branch and every
      // body-map region combination gets built at least once.
      final samples = <Exercise>[];
      for (final pattern in MovementPattern.values) {
        final match = repo.all.where((e) => e.pattern == pattern);
        if (match.isNotEmpty) samples.add(match.first);
      }
      expect(samples.length, greaterThan(15));

      for (final exercise in samples) {
        await tester.pumpWidget(
          wrap(container, ExerciseDetailScreen(exercise: exercise)),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.takeException(),
          isNull,
          reason: 'detail screen threw for ${exercise.name}',
        );
      }
    });

    testWidgets('the tabbed shell builds every tab', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);
      container.read(planProvider.notifier).build(onboardedProfile);

      await tester.pumpWidget(wrap(container, const RootScreen()));
      await tester.pump(const Duration(seconds: 1));

      for (final label in ['Plan', 'Library', 'Progress', 'Learn', 'At home']) {
        await tester.tap(find.text(label).last);
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.takeException(),
          isNull,
          reason: 'switching to $label threw',
        );
      }
    });
  });

  group('running a workout', () {
    testWidgets('logging a set marks it done and starts the rest timer', (
      tester,
    ) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      final plan = container
          .read(planProvider.notifier)
          .build(onboardedProfile);
      container.read(sessionProvider.notifier).start(plan.days.first);

      await tester.pumpWidget(wrap(container, const SessionScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      final session = container.read(sessionProvider)!;
      expect(session.exercises, isNotEmpty);
      expect(session.progress, 0);

      // Find the first exercise that has real sets rather than a warm-up tick.
      final index = session.exercises.indexWhere((e) => e.sets.length > 1);
      expect(index, isNot(-1));

      container
          .read(sessionProvider.notifier)
          .completeSet(index, 0, reps: 10, weight: 20);
      await tester.pump(const Duration(milliseconds: 100));

      final after = container.read(sessionProvider)!;
      expect(after.exercises[index].sets[0].done, isTrue);
      expect(after.exercises[index].sets[0].reps, 10);
      expect(after.exercises[index].sets[0].weight, 20);
      expect(after.totalSetsDone, 1);

      // Rest should be running, because more sets remain on this exercise.
      final rest = container.read(restTimerProvider);
      expect(rest.running, isTrue);
      expect(rest.remaining, greaterThan(0));

      // And the weight is remembered for next time.
      expect(
        container.read(lastWeightsProvider)[after.exercises[index].exerciseId],
        20,
      );

      container.read(restTimerProvider.notifier).skip();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('finishing moves the session into history', (tester) async {
      final container = await harness(profile: onboardedProfile);
      addTearDown(container.dispose);

      final plan = container
          .read(planProvider.notifier)
          .build(onboardedProfile);
      final controller = container.read(sessionProvider.notifier);
      controller.start(plan.days.first);

      final index = container
          .read(sessionProvider)!
          .exercises
          .indexWhere((e) => e.sets.length > 1);
      controller.completeSet(index, 0, reps: 10, weight: 40);

      final finished = controller.finish();

      expect(finished, isNotNull);
      expect(finished!.isFinished, isTrue);
      expect(finished.totalVolume, 400);
      expect(container.read(sessionProvider), isNull);
      expect(container.read(historyProvider), hasLength(1));
      expect(container.read(streakProvider), 1);
      expect(container.read(sessionsThisWeekProvider), hasLength(1));

      // The next offered day should have advanced past the one just completed.
      expect(container.read(nextDayIndexProvider), 1);

      await tester.pumpWidget(wrap(container, const ProgressScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Progress'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an interrupted session is restored from storage', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await Storage.open();
      await storage.writeProfile(onboardedProfile);

      final first = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(storage),
          exerciseRepoProvider.overrideWithValue(repo),
        ],
      );
      final plan = first.read(planProvider.notifier).build(onboardedProfile);
      first.read(sessionProvider.notifier).start(plan.days.first);
      final index = first
          .read(sessionProvider)!
          .exercises
          .indexWhere((e) => e.sets.length > 1);
      first
          .read(sessionProvider.notifier)
          .completeSet(index, 0, reps: 8, weight: 15);
      await tester.pump(const Duration(milliseconds: 50));
      first.dispose();

      // A fresh container over the same storage: the phone died and came back.
      final second = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(storage),
          exerciseRepoProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(second.dispose);

      final restored = second.read(sessionProvider);
      expect(restored, isNotNull);
      expect(restored!.exercises[index].sets[0].done, isTrue);
      expect(restored.exercises[index].sets[0].weight, 15);
    });
  });
}
