import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'motion.dart';

/// The app's default push transition.
///
/// The incoming page rises a short distance and fades in on a strong ease-out;
/// the outgoing page settles back and dims rather than sliding away. That
/// difference in treatment is what reads as depth -- one layer arrives, the
/// other recedes -- instead of two pages sliding past each other.
class FPageRoute<T> extends PageRoute<T> {
  FPageRoute({required this.builder, this.fullscreen = false, super.settings});

  final WidgetBuilder builder;

  /// A modal-feeling page (a workout session) comes up from the bottom edge
  /// instead of easing forward, so leaving it later feels like coming back down.
  final bool fullscreen;

  @override
  Duration get transitionDuration => FDur.page;

  @override
  Duration get reverseTransitionDuration => FDur.pageBack;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotionOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    final enter = CurvedAnimation(
      parent: animation,
      curve: FCurve.out,
      reverseCurve: FCurve.exit,
    );
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: FCurve.out);

    return AnimatedBuilder(
      animation: exit,
      builder: (context, inner) {
        // The page this one covers pulls back and dims -- the "behind" layer.
        final t = exit.value;
        return Transform.scale(
          scale: 1 - 0.02 * t,
          child: Opacity(opacity: 1 - 0.35 * t, child: inner),
        );
      },
      child: AnimatedBuilder(
        animation: enter,
        builder: (context, inner) {
          final t = enter.value;
          final dy = fullscreen ? 64.0 : 18.0;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * dy),
              child: Transform.scale(
                scale: fullscreen ? 1.0 : 0.99 + 0.01 * t,
                child: inner,
              ),
            ),
          );
        },
        child: child,
      ),
    );
  }
}

/// A route that fades one full screen into another with no movement at all.
/// Used where a positional change would be a lie -- splash to app, for instance,
/// where nothing is "further in", it is the same place becoming ready.
class FFadeRoute<T> extends PageRoute<T> {
  FFadeRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => FDur.slow;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}

/// Onboarding's forward/back transition.
///
/// Steps live on one horizontal axis, so they move along it -- forward pushes
/// left, back pushes right. Keeping the axis honest is what lets someone build a
/// mental model of "how far in am I" without a breadcrumb.
class StepTransition extends StatelessWidget {
  const StepTransition({
    super.key,
    required this.child,
    required this.forward,
    required this.stepKey,
  });

  final Widget child;
  final bool forward;
  final Object stepKey;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    return AnimatedSwitcher(
      duration: FDur.slow,
      reverseDuration: FDur.fast,
      switchInCurve: FCurve.out,
      switchOutCurve: FCurve.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previous.map((p) => Positioned.fill(child: p)),
          if (current != null) current,
        ],
      ),
      transitionBuilder: (child, animation) {
        if (reduce) return FadeTransition(opacity: animation, child: child);
        final incoming = child.key == ValueKey(stepKey);
        // Outgoing content leaves the way it came in, mirrored.
        final dir = incoming ? (forward ? 1.0 : -1.0) : (forward ? -1.0 : 1.0);
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, inner) => Transform.translate(
              offset: Offset((1 - animation.value) * 28 * dir, 0),
              child: inner,
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(stepKey), child: child),
    );
  }
}

/// Scrim used behind modal surfaces.
class FScrim extends StatelessWidget {
  const FScrim({super.key, required this.progress, this.onTap});

  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: progress < 0.05,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          // A light veil, not a blackout: on a white app a heavy scrim reads
          // as the screen having failed rather than as a layer above it.
          color: FColors.text.withValues(
            alpha: 0.28 * progress.clamp(0.0, 1.0),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
