import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Wraps any tappable surface with press feedback.
///
/// The scale fires on pointer *down*, not on release. Waiting for the tap to
/// complete is the single most common way an app ends up feeling dead: the user
/// has already committed, and the interface has not acknowledged it yet.
class PressFx extends StatefulWidget {
  const PressFx({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Subtle by design. Below ~0.95 the whole surface visibly shrinks, which
  /// reads as a toy rather than a control.
  final double scale;
  final bool haptic;
  final bool enabled;
  final HitTestBehavior behavior;

  @override
  State<PressFx> createState() => _PressFxState();
}

class _PressFxState extends State<PressFx> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: FDur.press,
    reverseDuration:
        FDur.base, // release is slower than press: settle, don't snap back
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _interactive ? (_) => _c.forward() : null,
      onTapUp: _interactive ? (_) => _c.reverse() : null,
      onTapCancel: _interactive ? () => _c.reverse() : null,
      onTap: _interactive
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      onLongPress: _interactive && widget.onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!.call();
            }
          : null,
      child: reduce
          ? widget.child
          : AnimatedBuilder(
              animation: _c,
              builder: (context, child) => Transform.scale(
                scale: 1 - (1 - widget.scale) * FCurve.out.transform(_c.value),
                child: child,
              ),
              child: widget.child,
            ),
    );
  }
}

/// Entrance animation for content that appears when a screen opens.
///
/// Rises a short distance while fading in. The distance is deliberately small --
/// motion here is meant to draw the eye down the page in order, not to be noticed
/// as an animation.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
    this.duration = FDur.slow,
    this.axis = Axis.vertical,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;
  final Axis axis;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      // Held so it can be cancelled: a screen dismissed mid-stagger would
      // otherwise leave a timer pending on a disposed widget.
      _delayTimer = Timer(widget.delay, _c.forward);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = FCurve.out.transform(_c.value);
        final d = (1 - t) * widget.offset;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.axis == Axis.vertical ? Offset(0, d) : Offset(d, 0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Entrance delay for the nth item in a list.
///
/// Delays stay short: past roughly 60ms per item the cascade stops feeling
/// crafted and starts feeling like the screen is loading slowly. Capped so a
/// long list never leaves the last row waiting seconds to appear.
Duration staggerDelay(
  int index, {
  Duration interval = const Duration(milliseconds: 40),
  Duration baseDelay = Duration.zero,
  int maxSteps = 8,
}) => baseDelay + interval * math.min(index, maxSteps);

/// Rolls a number up to its value instead of snapping.
///
/// Only worth it for figures that represent an accumulation the user just earned
/// -- total volume, a new streak. Animating an arbitrary readout wastes the
/// gesture and makes the number harder to read.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.decimals = 0,
    this.suffix = '',
    this.prefix = '',
  });

  final double value;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;
  final int decimals;
  final String suffix;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) {
      return Text(
        '$prefix${value.toStringAsFixed(decimals)}$suffix',
        style: style,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: FCurve.out,
      builder: (context, v, _) =>
          Text('$prefix${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}
