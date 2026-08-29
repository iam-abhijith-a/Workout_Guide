import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show Material, MaterialApp, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_guide/core/theme/tokens.dart';
import 'package:workout_guide/core/theme/typography.dart';
import 'package:workout_guide/data/models/exercise.dart';

/// Wraps a screen in the minimum app scaffolding it expects: a container for
/// state, a `MaterialApp` for routing and overlays, and the default text style
/// the real app installs.
///
/// Sized to a common phone rather than the test default of 800x600, because a
/// layout overflow at 800px wide is not the bug anyone cares about.
Widget wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          devicePixelRatio: 3,
          padding: EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Material(
          color: FColors.canvas,
          child: DefaultTextStyle(style: FType.body, child: child),
        ),
      ),
    ),
  );
}

/// The full 1,324-exercise library the app ships with.
///
/// The tests deliberately run over the real data rather than a fixture,
/// because the failure modes are all about what the real data contains. That
/// file is generated from the `exercises-dataset` submodule and is not
/// committed, so a fresh clone has to build it first.
List<Exercise> loadLibrary() {
  final file = File('assets/data/exercises.json');
  if (!file.existsSync()) {
    throw StateError(
      'assets/data/exercises.json is missing. It is generated from the '
      'exercises-dataset submodule and is not committed. From the repo root:\n'
      '  git submodule update --init\n'
      '  python tools/build_data.py',
    );
  }
  return (jsonDecode(file.readAsStringSync()) as List)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList();
}
