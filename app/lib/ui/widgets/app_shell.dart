import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/widgets.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'media.dart';
import 'surfaces.dart';

/// The bottom navigation bar.
///
/// Tabs get pressed dozens of times a day, so nothing here waits: the label and
/// icon change immediately and the only motion is the indicator sliding, which
/// carries the spatial information. Anything longer would be tax on every
/// single navigation.
class FTabBar extends StatelessWidget {
  const FTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.tabs,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<({FIconData icon, String label})> tabs;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return FGlassBar(
      child: Padding(
        padding: EdgeInsets.only(
          top: FSpace.sm,
          bottom: FSpace.sm + bottomInset,
          left: FSpace.sm,
          right: FSpace.sm,
        ),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _Tab(
                  icon: tabs[i].icon,
                  label: tabs[i].label,
                  selected: i == index,
                  onTap: () {
                    if (i == index) return;
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: PressFx(
        onTap: onTap,
        scale: 0.9,
        haptic: false, // the tab bar fires its own, only on an actual change
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: selected ? 1 : 0),
                duration: FDur.base,
                curve: FCurve.out,
                builder: (context, t, _) => Transform.translate(
                  // A single pixel of lift. Not consciously visible; what it
                  // does is make the selected tab feel picked up.
                  offset: Offset(0, -1.5 * t),
                  child: FIcon(
                    icon,
                    size: 22,
                    color: Color.lerp(FColors.textMuted, FColors.text, t),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: FDur.base,
                curve: FCurve.out,
                style: FType.caption.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? FColors.text : FColors.textMuted,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cross-fades between tab bodies while keeping every tab's state alive.
///
/// An `AnimatedSwitcher` would rebuild the whole subtree on each switch, which
/// throws away scroll position and filter state -- losing your place in a
/// 1,324-item library because you glanced at another tab is infuriating. Here
/// every page stays mounted; only its opacity changes, and hidden pages are
/// taken offstage so they cost nothing to lay out or paint.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: FDur.base,
    value: 1,
  );

  late int _current = widget.index;
  int? _outgoing;

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (widget.index != _current) {
      setState(() {
        _outgoing = _current;
        _current = widget.index;
      });
      _c
        ..value = 0
        ..forward().whenComplete(() {
          if (mounted) setState(() => _outgoing = null);
        });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = reduce ? 1.0 : FCurve.out.transform(_c.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              Offstage(
                offstage: i != _current && i != _outgoing,
                child: TickerMode(
                  // Animations in a hidden tab must not keep ticking; a rest
                  // timer ring spinning behind an invisible page is pure drain.
                  enabled: i == _current,
                  child: IgnorePointer(
                    ignoring: i != _current,
                    child: Opacity(
                      opacity: i == _current ? t : (1 - t),
                      child: widget.children[i],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Standard screen scaffold: a large title that collapses into a compact bar as
/// the content scrolls under it.
class FScreen extends StatefulWidget {
  const FScreen({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.bottomPadding = FSpace.x5l,
  });

  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Widget? leading;
  final double bottomPadding;

  @override
  State<FScreen> createState() => _FScreenState();
}

class _FScreenState extends State<FScreen> {
  final _controller = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    // One threshold with a dead zone rather than a continuous interpolation:
    // a title that smoothly shrinks with every pixel of scroll is distracting,
    // and it never settles.
    final shouldCollapse = _controller.offset > 28;
    if (shouldCollapse != _collapsed) {
      setState(() => _collapsed = shouldCollapse);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    // Paints its own background. A pushed opaque route has no ancestor
    // supplying one, so any screen that did not happen to be wrapped in an
    // FBackdrop rendered over black.
    return ColoredBox(
      color: FColors.canvas,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FSpace.gutter,
                    topInset + FSpace.xxl,
                    FSpace.gutter,
                    FSpace.xl,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: FSpace.md),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: FType.h1),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: FSpace.xs),
                              Text(widget.subtitle!, style: FType.small),
                            ],
                          ],
                        ),
                      ),
                      for (final action in widget.actions) ...[
                        const SizedBox(width: FSpace.sm),
                        action,
                      ],
                    ],
                  ),
                ),
              ),
              ...widget.slivers,
              SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
            ],
          ),
          // The compact bar only materialises once content is actually behind it.
          // A permanent bar over a top-of-page view is chrome for its own sake.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_collapsed,
              child: AnimatedOpacity(
                opacity: _collapsed ? 1 : 0,
                duration: FDur.base,
                curve: FCurve.out,
                child: FGlassBar(
                  border: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FSpace.gutter,
                      topInset + FSpace.md,
                      FSpace.gutter,
                      FSpace.md,
                    ),
                    child: Row(
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: FSpace.md),
                        ],
                        Expanded(
                          child: Text(
                            widget.title,
                            style: FType.h2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final action in widget.actions) ...[
                          const SizedBox(width: FSpace.sm),
                          action,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page background. Flat white -- structure comes from borders, not from a wash.
class FBackdrop extends StatelessWidget {
  const FBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: FColors.canvas, child: child);
}
