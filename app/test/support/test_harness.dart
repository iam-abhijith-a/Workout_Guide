import 'package:flutter/material.dart' show Material, MaterialApp, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_guide/core/theme/tokens.dart';
import 'package:workout_guide/core/theme/typography.dart';

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
