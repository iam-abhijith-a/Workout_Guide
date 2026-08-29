import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_guide/data/models/exercise.dart';
import 'package:workout_guide/data/models/profile.dart';
import 'package:workout_guide/data/repositories/exercise_repository.dart';
import 'package:workout_guide/data/repositories/storage.dart';
import 'package:workout_guide/state/providers.dart';
import 'package:workout_guide/ui/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

/// Advances past any in-flight transition.
///
/// Several frames, not one: a single `pump` moves the clock but only renders
/// once, so the outgoing step stays mounted and every `findsOneWidget` sees two
/// copies of the question. `pumpAndSettle` is avoided so a looping animation
/// anywhere in the tree cannot hang the test.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Onboarding is the only path to a plan, so it gets walked end to end: every
/// step rendered, every answer recorded, and the guard rails that stop a novice
/// over-committing actually enforced.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseRepository repo;

  setUpAll(() {
    repo = ExerciseRepository.fromExercises(loadLibrary());
  });

  Future<ProviderContainer> harness() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    return ProviderContainer(
      overrides: [
        storageProvider.overrideWithValue(storage),
        exerciseRepoProvider.overrideWithValue(repo),
      ],
    );
  }

  Future<void> advance(WidgetTester tester) async {
    await tester.tap(find.textContaining(RegExp('Get started|Continue')).last);
    await settle(tester);
  }

  testWidgets('every step renders and advances', (tester) async {
    final container = await harness();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container, const OnboardingScreen()));
    await settle(tester);

    // 1. Welcome
    expect(find.textContaining('90 days'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    await advance(tester);

    // 2. Goal
    expect(find.textContaining('your goal'), findsOneWidget);
    expect(find.text('Build muscle'), findsOneWidget);
    await tester.tap(find.text('Build muscle'));
    await settle(tester);
    await advance(tester);

    // 3. Experience
    expect(find.textContaining('you trained'), findsOneWidget);
    await tester.tap(find.text('Tried it before'));
    await settle(tester);
    await advance(tester);

    // 4. Days — and the week it produces is previewed alongside the choice.
    expect(find.textContaining('many days'), findsOneWidget);
    expect(find.textContaining('Full Body'), findsWidgets);
    await tester.tap(find.text('4'));
    await settle(tester);
    expect(find.textContaining('Upper'), findsWidgets);
    await advance(tester);

    // 5. Equipment
    expect(find.textContaining('get to?'), findsOneWidget);
    expect(find.text('Build my plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answers are written to the profile on finish', (tester) async {
    final container = await harness();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container, const OnboardingScreen()));
    await settle(tester);

    await advance(tester); // welcome
    await tester.tap(find.text('Get stronger'));
    await settle(tester);
    await advance(tester); // goal
    await tester.tap(find.text('Training regularly'));
    await settle(tester);
    await advance(tester); // experience
    await tester.tap(find.text('5'));
    await settle(tester);
    await advance(tester); // days

    await tester.tap(find.text('I have a full gym membership'));
    await settle(tester);
    await tester.tap(find.text('Build my plan'));
    await tester.pump();

    final profile = container.read(profileProvider);
    expect(profile.onboarded, isTrue);
    expect(profile.goal, Goal.strength);
    expect(profile.experience, Experience.regular);
    expect(profile.daysPerWeek, 5);
    expect(profile.equipment, contains(EquipClass.barbell));
    expect(profile.equipment, contains(EquipClass.machine));
    expect(profile.createdAt, isNotNull);

    // Finishing must leave a usable plan behind, not just a profile.
    expect(container.read(planProvider), isNotNull);
    expect(container.read(planProvider)!.days, hasLength(5));
  });

  testWidgets('a complete novice cannot pick five days a week', (tester) async {
    final container = await harness();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container, const OnboardingScreen()));
    await settle(tester);

    await advance(tester); // welcome
    await advance(tester); // goal, leaving the default
    await advance(tester); // experience, leaving "Never trained"

    expect(find.textContaining('many days'), findsOneWidget);
    // Four and five stay visible but inert, so the reason is on screen rather
    // than the options silently missing.
    expect(find.textContaining('open up once'), findsOneWidget);

    await tester.tap(find.text('5'));
    await settle(tester);
    await advance(tester);
    await tester.tap(find.text('Build my plan'));
    await tester.pump();

    expect(container.read(profileProvider).daysPerWeek, lessThanOrEqualTo(3));
  });

  testWidgets('you cannot continue with no equipment selected', (tester) async {
    final container = await harness();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container, const OnboardingScreen()));
    await settle(tester);

    for (var i = 0; i < 4; i++) {
      await advance(tester);
    }

    // Body weight is preselected; clearing it should disable the action rather
    // than letting someone build a plan out of nothing.
    await tester.tap(find.text('Body weight'));
    await settle(tester);

    await tester.tap(find.text('Build my plan'));
    await tester.pump();

    expect(container.read(profileProvider).onboarded, isFalse);
  });

  testWidgets('back returns to the previous answer', (tester) async {
    final container = await harness();
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container, const OnboardingScreen()));
    await settle(tester);

    await advance(tester); // welcome -> goal
    await tester.tap(find.text('Get stronger'));
    await settle(tester);
    await advance(tester); // goal -> experience

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);

    expect(find.textContaining('your goal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
