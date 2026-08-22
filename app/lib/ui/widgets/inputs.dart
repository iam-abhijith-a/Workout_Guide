import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/widgets.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'media.dart';

/// Text input styled to the design system.
///
/// Built on [EditableText] rather than Material's `TextField` so the border,
/// focus treatment and placeholder come from the app's tokens instead of
/// fighting an `InputDecoration`.
class FTextField extends StatefulWidget {
  const FTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.prefix,
    this.suffix,
    this.textAlign = TextAlign.start,
    this.style,
    this.height = 56,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? prefix;
  final Widget? suffix;
  final TextAlign textAlign;
  final TextStyle? style;
  final double height;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;

  @override
  State<FTextField> createState() => _FTextFieldState();
}

class _FTextFieldState extends State<FTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? FType.h2;

    return AnimatedContainer(
      duration: FDur.fast,
      curve: FCurve.out,
      padding: const EdgeInsets.symmetric(horizontal: FSpace.lg),
      height: widget.height,
      decoration: BoxDecoration(
        color: FColors.muted,
        borderRadius: FRadius.rLg,
        border: Border.all(
          color: _focused
              ? FColors.primary.withValues(alpha: 0.6)
              : FColors.border,
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          if (widget.prefix != null) ...[
            widget.prefix!,
            const SizedBox(width: FSpace.md),
          ],
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) => Stack(
                alignment: widget.textAlign == TextAlign.center
                    ? Alignment.center
                    : Alignment.centerLeft,
                children: [
                  if (value.text.isEmpty)
                    IgnorePointer(
                      child: Text(
                        widget.hint,
                        style: style.copyWith(color: FColors.textFaint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  child!,
                ],
              ),
              child: EditableText(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                style: style,
                textAlign: widget.textAlign,
                cursorColor: FColors.primary,
                backgroundCursorColor: FColors.border,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                inputFormatters: widget.inputFormatters,
                selectionColor: FColors.primary.withValues(alpha: 0.3),
                cursorWidth: 2,
                cursorRadius: const Radius.circular(1),
                textInputAction: widget.textInputAction,
              ),
            ),
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: FSpace.md),
            widget.suffix!,
          ],
        ],
      ),
    );
  }
}

/// Search field with a clear affordance that only appears once there is
/// something to clear.
class FSearchField extends StatelessWidget {
  const FSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => FTextField(
        controller: controller,
        hint: hint,
        height: 46,
        autofocus: autofocus,
        style: FType.label,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        prefix: const FIcon(FIcons.search, size: 17, color: FColors.textMuted),
        suffix: value.text.isEmpty
            ? null
            : PressFx(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                scale: 0.85,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: FIcon(
                    FIcons.close,
                    size: 15,
                    color: FColors.textMuted,
                  ),
                ),
              ),
      ),
    );
  }
}

/// A minus / value / plus control.
///
/// Sized for a phone propped on a bench with sweaty hands: 40px targets, a
/// tap-and-hold repeat for larger jumps, and haptics on every step so it is
/// usable without looking.
class NumberStepper extends StatefulWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 999,
    this.suffix,
    this.decimals = 0,
    this.width,
    this.onTapValue,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final double max;
  final String? suffix;
  final int decimals;

  /// Null means "fill the space you are given" -- which is what lets two
  /// steppers share a row without a fixed width that overflows on a narrow phone.
  final double? width;

  /// Lets the caller open a keypad when the number itself is tapped, for when
  /// stepping from 0 to 60kg would take a while.
  final VoidCallback? onTapValue;

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  void _bump(double delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    if (next == widget.value) return;
    HapticFeedback.selectionClick();
    widget.onChanged(next.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.decimals == 0
        ? widget.value.round().toString()
        : widget.value.toStringAsFixed(widget.decimals);

    return Container(
      width: widget.width,
      height: 44,
      decoration: BoxDecoration(
        color: FColors.muted,
        borderRadius: FRadius.rMd,
      ),
      child: Row(
        children: [
          _StepButton(
            icon: FIcons.minus,
            onTap: () => _bump(-widget.step),
            enabled: widget.value > widget.min,
          ),
          Expanded(
            child: PressFx(
              onTap: widget.onTapValue,
              scale: 0.94,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(text, style: FType.num),
                    if (widget.suffix != null) ...[
                      const SizedBox(width: 3),
                      Text(widget.suffix!, style: FType.caption),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _StepButton(
            icon: FIcons.plus,
            onTap: () => _bump(widget.step),
            enabled: widget.value < widget.max,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final FIconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PressFx(
      onTap: enabled ? onTap : null,
      haptic: false, // the stepper fires its own, only when the value moves
      scale: 0.88,
      child: SizedBox(
        width: 42,
        height: 44,
        child: Center(
          child: FIcon(
            icon,
            size: 15,
            color: enabled ? FColors.textSecondary : FColors.textFaint,
          ),
        ),
      ),
    );
  }
}

/// A labelled on/off switch.
class FToggle extends StatelessWidget {
  const FToggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PressFx(
      onTap: () => onChanged(!value),
      scale: 0.94,
      child: AnimatedContainer(
        duration: FDur.base,
        curve: FCurve.out,
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? FColors.primary : FColors.muted,
          borderRadius: BorderRadius.circular(FRadius.pill),
          border: Border.all(
            color: value ? FColors.primary : FColors.borderStrong,
          ),
        ),
        child: AnimatedAlign(
          duration: FDur.base,
          // A touch of overshoot: a switch is a physical metaphor, and a thumb
          // that settles into place sells it in a way a linear slide does not.
          curve: Cubic(0.34, 1.4, 0.5, 1),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? FColors.onPrimary : FColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
