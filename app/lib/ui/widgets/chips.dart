import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/widgets.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// A selectable filter chip.
///
/// Selected means filled near-black. No tick: at this size a tick steals space
/// from the label and reads as noise when a dozen are on screen.
class FChip extends StatefulWidget {
  const FChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.tone,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  /// Colours the selected fill. Carries body-part identity through from the
  /// library rows, so the same thing is the same colour everywhere.
  final Color? tone;
  final bool dense;

  @override
  State<FChip> createState() => _FChipState();
}

class _FChipState extends State<FChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fill = widget.tone ?? FColors.primary;
    final fg = widget.selected
        ? FColors.onPrimary
        : (_hovered ? FColors.text : FColors.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressFx(
        onTap: widget.onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: FDur.fast,
          curve: FCurve.out,
          height: widget.dense ? 30 : 36,
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 10 : FSpace.md,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? fill
                : (_hovered ? FColors.muted : FColors.surface),
            borderRadius: BorderRadius.circular(FRadius.pill),
            border: Border.all(
              color: widget.selected
                  ? fill
                  : (_hovered ? FColors.borderStrong : FColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 13),
                  child: widget.leading!,
                ),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: FDur.fast,
                curve: FCurve.out,
                style: FType.label.copyWith(color: fg),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small non-interactive label: difficulty, equipment, a count.
class FTag extends StatelessWidget {
  const FTag({super.key, required this.label, this.tone, this.dot = false});

  final String label;

  /// When set, the tag takes a wash of this colour. Reserved for tags that
  /// genuinely mean something -- a difficulty, a role -- rather than every tag
  /// on a screen shouting at once.
  final Color? tone;

  /// A colour dot instead of a tinted fill. Quieter, and it keeps every tag at
  /// the same visual weight while still colour-coding.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final tinted = tone != null && !dot;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: FSpace.sm),
      decoration: BoxDecoration(
        color: tinted ? FColors.wash(tone!) : FColors.muted,
        borderRadius: BorderRadius.circular(FRadius.sm),
        border: Border.all(
          color: tinted ? FColors.washBorder(tone!) : FColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot && tone != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: FType.caption.copyWith(
              color: tinted ? tone : FColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented control. The indicator is one pill that slides, so the eye tracks
/// a single object moving rather than two things changing colour.
class FSegmented<T> extends StatelessWidget {
  const FSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<({T value, String label})> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == value);
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 3.0;
        final itemWidth = (constraints.maxWidth - pad * 2) / options.length;
        return Container(
          height: 36,
          padding: const EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: FColors.muted,
            borderRadius: BorderRadius.circular(FRadius.md),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: FDur.base,
                curve: FCurve.out,
                left: itemWidth * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: FColors.surface,
                    borderRadius: BorderRadius.circular(FRadius.sm),
                    boxShadow: FShadow.sm,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: PressFx(
                        onTap: () => onChanged(option.value),
                        scale: 0.96,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: FDur.fast,
                            style: FType.label.copyWith(
                              color: option.value == value
                                  ? FColors.text
                                  : FColors.textMuted,
                            ),
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A row that behaves like a radio button and reads like a card.
///
/// Selection is a near-black border and a tick, not a colour fill -- a filled
/// row would fight the primary button at the bottom of the same screen.
class FChoiceRow extends StatefulWidget {
  const FChoiceRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
    this.multi = false,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  /// Draws a square rather than a circle -- the shape is the only honest signal
  /// that several may be picked.
  final bool multi;

  @override
  State<FChoiceRow> createState() => _FChoiceRowState();
}

class _FChoiceRowState extends State<FChoiceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressFx(
        onTap: widget.onTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: FDur.fast,
          curve: FCurve.out,
          padding: const EdgeInsets.all(FSpace.lg),
          decoration: BoxDecoration(
            color: _hovered && !widget.selected
                ? FColors.surfaceHover
                : FColors.surface,
            borderRadius: FRadius.rLg,
            border: Border.all(
              color: widget.selected
                  ? FColors.primary
                  : (_hovered ? FColors.borderStrong : FColors.border),
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: FSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: FType.h3),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: FType.small),
                  ],
                ),
              ),
              const SizedBox(width: FSpace.md),
              AnimatedCheck(
                checked: widget.selected,
                size: 20,
                circular: !widget.multi,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tick that confirms a choice.
///
/// The check draws along its own path rather than fading in -- a stroke being
/// made reads as "the app just did that", which a cross-fade never does.
class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({
    super.key,
    required this.checked,
    this.size = 20,
    this.fill = FColors.primary,
    this.mark = FColors.onPrimary,
    this.circular = false,
  });

  final bool checked;
  final double size;
  final Color fill;
  final Color mark;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: checked ? 1 : 0),
      duration: FDur.base,
      curve: FCurve.out,
      builder: (context, t, _) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0x00000000), fill, t),
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(size * 0.3),
          border: Border.all(
            color: Color.lerp(FColors.borderStrong, fill, t)!,
            width: 1.5,
          ),
        ),
        child: CustomPaint(
          painter: _CheckPainter(progress: t, color: mark),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.15) return;
    // The container fills over the first 15%; the stroke follows, so the tick
    // lands *into* a finished shape instead of racing it.
    final t = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.27, w * 0.52)
      ..lineTo(w * 0.44, w * 0.68)
      ..lineTo(w * 0.74, w * 0.34);

    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
