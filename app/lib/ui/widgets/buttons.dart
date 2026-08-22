import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/widgets.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Four variants, and there is no fifth.
///
/// A screen has exactly one [primary] on it. Everything else is [secondary] or
/// [ghost]. When two buttons on a screen both look important, neither is.
enum FButtonVariant { primary, secondary, ghost, destructive }

/// Three heights, all on the 4px grid: 32 / 40 / 48.
enum FButtonSize { sm, md, lg }

class FButton extends StatefulWidget {
  const FButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FButtonVariant.primary,
    this.size = FButtonSize.md,
    this.icon,
    this.trailing,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FButtonVariant variant;
  final FButtonSize size;
  final Widget? icon;
  final Widget? trailing;
  final bool expand;
  final bool loading;

  @override
  State<FButton> createState() => _FButtonState();
}

class _FButtonState extends State<FButton> {
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  ({Color bg, Color fg, Color? border}) get _palette =>
      switch (widget.variant) {
        FButtonVariant.primary => (
          bg: _hovered ? FColors.primaryHover : FColors.primary,
          fg: FColors.onPrimary,
          border: null,
        ),
        FButtonVariant.secondary => (
          bg: _hovered ? FColors.surfaceHover : FColors.surface,
          fg: FColors.text,
          border: _hovered ? FColors.borderStrong : FColors.border,
        ),
        FButtonVariant.ghost => (
          bg: _hovered ? FColors.muted : const Color(0x00000000),
          fg: FColors.textSecondary,
          border: null,
        ),
        FButtonVariant.destructive => (
          bg: FColors.wash(FColors.rose),
          fg: FColors.rose,
          border: FColors.washBorder(FColors.rose),
        ),
      };

  ({double h, double px, double icon}) get _metrics => switch (widget.size) {
    FButtonSize.sm => (h: 32, px: FSpace.md, icon: 14),
    FButtonSize.md => (h: 40, px: FSpace.lg, icon: 16),
    // Large is for the one action a screen exists to perform, and for the gym
    // floor where the phone is on a bench and the user is out of breath.
    FButtonSize.lg => (h: 48, px: FSpace.xl, icon: 17),
  };

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    final m = _metrics;
    final fg = _enabled ? p.fg : FColors.textFaint;

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressFx(
        onTap: _enabled ? widget.onPressed : null,
        enabled: _enabled,
        scale: 0.975,
        child: AnimatedContainer(
          duration: FDur.fast,
          curve: FCurve.out,
          height: m.h,
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: m.px),
          decoration: BoxDecoration(
            color: _enabled ? p.bg : FColors.muted,
            borderRadius: BorderRadius.circular(FRadius.md),
            border: p.border == null
                ? null
                : Border.all(color: _enabled ? p.border! : FColors.border),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                Padding(
                  padding: const EdgeInsets.only(right: FSpace.sm),
                  child: FSpinner(color: fg, size: m.icon),
                )
              else if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: FSpace.sm),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: m.icon),
                    child: widget.icon!,
                  ),
                ),
              Flexible(
                child: Text(
                  widget.label,
                  style: FType.label.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: FSpace.sm),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: m.icon),
                    child: widget.trailing!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A square icon-only button: back, close, toolbar actions.
class FIconButton extends StatefulWidget {
  const FIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 36,
    this.tone = FColors.textSecondary,
    this.bordered = true,
    this.semanticLabel,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final Color tone;
  final bool bordered;
  final String? semanticLabel;

  @override
  State<FIconButton> createState() => _FIconButtonState();
}

class _FIconButtonState extends State<FIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: PressFx(
          onTap: widget.onPressed,
          scale: 0.92,
          child: AnimatedContainer(
            duration: FDur.fast,
            curve: FCurve.out,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _hovered ? FColors.muted : FColors.surface,
              borderRadius: BorderRadius.circular(FRadius.md),
              border: widget.bordered
                  ? Border.all(
                      color: _hovered ? FColors.borderStrong : FColors.border,
                    )
                  : null,
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(color: widget.tone, size: 17),
                child: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading indicator.
///
/// A single arc rotating at a deliberately brisk pace -- a fast spinner makes
/// the wait *feel* shorter even when it is identical. Flat colour, no sweep
/// gradient.
class FSpinner extends StatefulWidget {
  const FSpinner({super.key, this.color = FColors.textMuted, this.size = 16});

  final Color color;
  final double size;

  @override
  State<FSpinner> createState() => _FSpinnerState();
}

class _FSpinnerState extends State<FSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _SpinnerPainter(turns: _c.value, color: widget.color),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({required this.turns, required this.color});

  final double turns;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      turns * math.pi * 2,
      math.pi * 0.6,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.turns != turns || old.color != color;
}
