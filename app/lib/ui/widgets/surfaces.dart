import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/widgets.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'media.dart';

/// The standard content surface.
class FCard extends StatefulWidget {
  const FCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(FSpace.lg),
    this.color = FColors.surface,
    this.borderColor,
    this.radius = FRadius.lg,
    this.elevated = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;
  final bool elevated;

  @override
  State<FCard> createState() => _FCardState();
}

class _FCardState extends State<FCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: PressFx(
        onTap: widget.onTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: FDur.fast,
          curve: FCurve.out,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hovered && interactive
                ? FColors.surfaceHover
                : widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color:
                  widget.borderColor ??
                  (_hovered && interactive
                      ? FColors.borderStrong
                      : FColors.border),
            ),
            boxShadow: widget.elevated ? FShadow.sm : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A labelled section with an optional trailing action.
class FSection extends StatelessWidget {
  const FSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.subtitle,
    this.tone,
    this.padding = const EdgeInsets.symmetric(horizontal: FSpace.gutter),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  /// When set, a short coloured rule sits beside the heading. Used where
  /// several sections stack and their *kind* matters -- the roles inside a
  /// training day -- so the groups separate without extra chrome.
  final Color? tone;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tone != null) ...[
                Container(
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(top: 2, right: FSpace.md),
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: FType.h2),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: FType.small),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        const SizedBox(height: FSpace.md),
        child,
      ],
    );
  }
}

/// Translucent chrome that content scrolls beneath.
///
/// A blurred layer rather than an opaque bar, so the page reads as one continuous
/// surface with a floating control strip on top -- the bar belongs to the screen
/// rather than cutting a slice out of it.
class FGlassBar extends StatelessWidget {
  const FGlassBar({
    super.key,
    required this.child,
    this.blur = 24,
    this.opacity = 0.72,
    this.border = true,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final reduceTransparency = MediaQuery.maybeHighContrastOf(context) ?? false;
    if (reduceTransparency) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: FColors.canvas,
          border: border
              ? const Border(top: BorderSide(color: FColors.border))
              : null,
        ),
        child: child,
      );
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FColors.canvas.withValues(alpha: opacity),
            border: border
                ? Border(
                    top: BorderSide(
                      color: FColors.border.withValues(alpha: 0.8),
                    ),
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Fades content out where it passes under floating chrome, instead of cutting
/// it with a hard divider line.
///
/// The `LinearGradient` below is an *alpha mask*, not a colour gradient -- it
/// carries no hue at all, and it is the only gradient left in the app.
class FadeEdge extends StatelessWidget {
  const FadeEdge({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    if (top == 0 && bottom == 0) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final h = bounds.height;
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [
            0.0,
            (top / h).clamp(0.0, 0.5),
            (1 - bottom / h).clamp(0.5, 1.0),
            1.0,
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// A bottom sheet you can actually throw.
///
/// Drag tracks the finger one-to-one, resists past the top edge instead of
/// stopping dead, and on release projects where the gesture was heading rather
/// than testing whether it crossed an arbitrary line. A quick flick dismisses
/// even if it barely moved, which is how people expect to close things.
Future<T?> showFSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool dismissible = true,
  double? maxHeightFraction,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetRoute<T>(
      builder: builder,
      dismissible: dismissible,
      maxHeightFraction: maxHeightFraction ?? 0.88,
    ),
  );
}

class _SheetRoute<T> extends PopupRoute<T> {
  _SheetRoute({
    required this.builder,
    required this.dismissible,
    required this.maxHeightFraction,
  });

  final Widget Function(BuildContext) builder;
  final bool dismissible;
  final double maxHeightFraction;

  @override
  Duration get transitionDuration => FDur.sheet;

  @override
  Duration get reverseTransitionDuration => FDur.sheetOut;

  @override
  bool get barrierDismissible => dismissible;

  @override
  Color? get barrierColor => FColors.text.withValues(alpha: 0.32);

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _SheetShell(
    route: this,
    maxHeightFraction: maxHeightFraction,
    child: Builder(builder: builder),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child; // the shell drives its own motion so a drag can interrupt it
}

class _SheetShell extends StatefulWidget {
  const _SheetShell({
    required this.route,
    required this.child,
    required this.maxHeightFraction,
  });

  final PopupRoute<dynamic> route;
  final Widget child;
  final double maxHeightFraction;

  @override
  State<_SheetShell> createState() => _SheetShellState();
}

class _SheetShellState extends State<_SheetShell>
    with SingleTickerProviderStateMixin {
  /// 0 = fully hidden below the edge, 1 = fully open. Driving one normalised
  /// value keeps drag and animation on the same scale, which is what lets a
  /// drag grab an in-flight animation without a jump.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: FDur.sheet,
    reverseDuration: FDur.sheetOut,
  );

  double _height = 0;

  @override
  void initState() {
    super.initState();
    _c.animateTo(1, curve: FCurve.drawer);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    _c.stop(); // adopt the animation's current value, mid-flight
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_height == 0) return;
    final delta = d.primaryDelta! / _height;
    var next = _c.value - delta;
    if (next > 1) {
      // Past fully open: resist rather than refuse, so the sheet still feels
      // physical at its limit.
      final overshoot = (next - 1) * _height;
      next = 1 + rubberband(overshoot, _height) / _height;
    }
    _c.value = next.clamp(0.0, 1.08);
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity =
        -d.primaryVelocity! / _height; // fraction per second, up positive

    // Where would it come to rest if released now? Snap to whichever end that
    // projection is closer to, so a fast flick wins over a small distance.
    final projected = (_c.value + projectMomentum(velocity) / 4).clamp(
      -0.5,
      1.5,
    );
    final shouldClose = projected < 0.62;

    if (shouldClose) {
      _c
          .animateWith(SpringSimulation(FSpring.snappy, _c.value, 0, velocity))
          .whenCompleteOrCancel(() {
            if (mounted && _c.value <= 0.02) Navigator.of(context).pop();
          });
    } else {
      _c.animateWith(
        SpringSimulation(
          // Bounce is earned here: the user threw it, so a little overshoot
          // reads as momentum rather than as a glitch.
          velocity.abs() > 0.4 ? FSpring.bouncy : FSpring.snappy,
          _c.value,
          1,
          velocity,
        ),
      );
    }
  }

  Future<void> _close() async {
    await _c.animateTo(0, duration: FDur.sheetOut, curve: FCurve.exit);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * widget.maxHeightFraction;

    return Stack(
      children: [
        // Tapping outside closes -- but only once the sheet is actually up.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _c.value > 0.5 ? _close : null,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, (1 - _c.value) * math.max(_height, 1)),
              child: child,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: GestureDetector(
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: _MeasureSize(
                  onChange: (size) => _height = size.height,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: FColors.canvas,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(FRadius.xl),
                      ),
                      border: Border(top: BorderSide(color: FColors.border)),
                      boxShadow: FShadow.sheet,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Grabber(),
                        Flexible(child: widget.child),
                        SizedBox(height: media.padding.bottom),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FSpace.md),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: FColors.borderStrong,
          borderRadius: BorderRadius.circular(FRadius.pill),
        ),
      ),
    );
  }
}

/// Reports its child's size after layout, so the sheet can translate by its own
/// height without hardcoding one.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRender(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureSizeRender renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRender extends RenderProxyBox {
  _MeasureSizeRender(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (_last != size) {
      _last = size;
      onChange(size);
    }
  }
}

/// Sheet header: title, optional subtitle, and a close affordance.
class FSheetHeader extends StatelessWidget {
  const FSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FSpace.gutter,
        0,
        FSpace.gutter,
        FSpace.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FType.h1),
                if (subtitle != null) ...[
                  const SizedBox(height: FSpace.xs),
                  Text(subtitle!, style: FType.small),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Empty state.
///
/// Deliberately quiet -- an empty screen should not shout -- but not colourless:
/// the tinted plate keeps it looking like a considered state rather than a
/// screen that failed to load.
class FEmptyState extends StatelessWidget {
  const FEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.tone = FColors.textMuted,
    this.action,
  });

  final String title;

  /// One sentence. Nobody reads a paragraph on a screen with nothing on it.
  final String message;
  final FIconData? icon;
  final Color tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FSpace.x3l),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                FIconTile(icon: icon!, tone: tone, size: 44),
                const SizedBox(height: FSpace.lg),
              ],
              Text(title, style: FType.h2, textAlign: TextAlign.center),
              const SizedBox(height: FSpace.xs),
              Text(message, style: FType.small, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: FSpace.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
