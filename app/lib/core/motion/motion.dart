import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// The app's motion vocabulary.
///
/// Two rules run through all of it:
///
/// 1. Things the user sees dozens of times a day move fast or not at all. Things
///    they see occasionally can take their time.
/// 2. Anything entering or leaving uses an ease-*out*. `easeIn` delays movement
///    at exactly the moment the eye is watching, which reads as lag.
abstract final class FDur {
  /// Press feedback. Any slower and the button feels like it is thinking.
  static const press = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 280);

  /// Route transitions. Longer than in-page motion because the whole surface moves.
  static const page = Duration(milliseconds: 340);
  static const pageBack = Duration(
    milliseconds: 260,
  ); // exits are faster than entrances

  static const sheet = Duration(milliseconds: 380);
  static const sheetOut = Duration(milliseconds: 240);

  /// Deliberate, one-off moments: plan reveal, workout summary, logo draw.
  static const ceremony = Duration(milliseconds: 900);
}

abstract final class FCurve {
  /// The house ease-out. Much stronger than [Curves.easeOut] -- it moves
  /// immediately, then glides, which is what makes UI feel responsive.
  static const out = Cubic(0.23, 1, 0.32, 1);

  /// For elements moving between two on-screen positions.
  static const inOut = Cubic(0.77, 0, 0.175, 1);

  /// The iOS drawer curve. Very fast off the mark, very long settle.
  static const drawer = Cubic(0.32, 0.72, 0, 1);

  /// Exits. Slightly accelerating is correct on the way *out* -- the element is
  /// leaving, so getting out of the way quickly is the point.
  static const exit = Cubic(0.4, 0, 1, 1);

  static const linear = Curves.linear;
}

/// Apple's two-parameter spring, which is far easier to reason about than
/// mass/stiffness/damping: `bounce` controls overshoot, `duration` controls how
/// quickly it gets there.
///
/// Default to [snappy] (no overshoot). Only reach for bounce when the user's own
/// gesture carried momentum into the motion -- overshoot on something that merely
/// faded in looks like a bug.
abstract final class FSpring {
  static const snappy = SpringDescription(mass: 1, stiffness: 320, damping: 36);
  static const gentle = SpringDescription(mass: 1, stiffness: 180, damping: 26);

  /// Slight overshoot, for flick- and drag-released motion.
  static const bouncy = SpringDescription(mass: 1, stiffness: 300, damping: 24);

  static SpringSimulation simulation({
    required double from,
    required double to,
    double velocity = 0,
    SpringDescription spring = snappy,
  }) => SpringSimulation(spring, from, to, velocity);
}

/// A [Curve] backed by a real spring simulation, so a spring feel can be dropped
/// into any widget that takes a curve without hand-driving a controller.
class SpringCurve extends Curve {
  SpringCurve({SpringDescription spring = FSpring.snappy})
    : _sim = SpringSimulation(spring, 0, 1, 0);

  final SpringSimulation _sim;

  @override
  double transformInternal(double t) => _sim.x(t) + t * (1 - _sim.x(1.0));
}

/// Momentum projection, straight from Apple's *Designing Fluid Interfaces*.
///
/// Answers "where would this come to rest if I let go now?" so a flick lands
/// where the gesture was heading rather than snapping back to the nearest edge.
double projectMomentum(double velocity, {double decelerationRate = 0.998}) {
  return (velocity / 1000) * decelerationRate / (1 - decelerationRate);
}

/// Progressive resistance past a boundary. Real objects slow before they stop;
/// an invisible wall reads as the app having frozen.
double rubberband(
  double overshoot,
  double dimension, {
  double constant = 0.55,
}) {
  if (dimension <= 0) return overshoot;
  return (overshoot * dimension * constant) /
      (dimension + constant * overshoot.abs());
}

/// Reduced motion means gentler, not absent: opacity and colour still carry
/// meaning, but translation, scale and overshoot are dropped.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ??
    MediaQuery.maybeAccessibleNavigationOf(context) ??
    false;
