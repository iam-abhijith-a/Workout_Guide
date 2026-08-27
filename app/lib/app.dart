import 'package:flutter/material.dart'
    show
        Material,
        MaterialApp,
        ThemeData,
        Brightness,
        ColorScheme,
        ScrollbarThemeData,
        WidgetStateProperty;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/tokens.dart';
import 'core/theme/typography.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/root_screen.dart';
import 'ui/widgets/logo.dart';
import 'state/providers.dart';

/// Root widget.
///
/// [MaterialApp] is used purely as a host for routing, overlays and text
/// selection -- every visual surface below it is custom. That keeps the app off
/// Material's look while still getting its well-tested plumbing.
class ForgeApp extends ConsumerWidget {
  const ForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Workout Guide',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: const _Boot(),
      builder: (context, child) {
        // Ignore the OS font-scale beyond a sane range. The layouts adapt, but
        // a 2x scale on a workout screen pushes the set list off the bottom,
        // which is worse for everyone than a slightly smaller number.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: DefaultTextStyle(
            style: FType.body,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  static final _theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    scaffoldBackgroundColor: FColors.canvas,
    canvasColor: FColors.canvas,
    colorScheme: const ColorScheme.light(
      surface: FColors.canvas,
      primary: FColors.primary,
      onPrimary: FColors.onPrimary,
      secondary: FColors.primary,
      error: FColors.rose,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(FColors.borderStrong),
      thickness: WidgetStateProperty.all(4),
      radius: const Radius.circular(2),
    ),
  );
}

/// Holds the splash until its draw completes, then routes to onboarding or the
/// app proper depending on whether this person has been here before.
class _Boot extends ConsumerStatefulWidget {
  const _Boot();

  @override
  ConsumerState<_Boot> createState() => _BootState();
}

class _BootState extends ConsumerState<_Boot> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    final onboarded = ref.watch(profileProvider).onboarded;

    return Material(
      color: FColors.canvas,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: !_ready
            ? ForgeSplash(
                key: const ValueKey('splash'),
                onReady: () {
                  if (mounted) setState(() => _ready = true);
                },
              )
            : (onboarded
                  ? const RootScreen(key: ValueKey('root'))
                  : const OnboardingScreen(key: ValueKey('onboarding'))),
      ),
    );
  }
}
