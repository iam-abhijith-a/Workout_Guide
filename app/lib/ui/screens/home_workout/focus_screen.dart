import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/exercise.dart';
import '../../../state/home_workout_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../library/exercise_detail_screen.dart';
import '../library/library_screen.dart' show DifficultyPips;
import 'home_filter_sheet.dart';
import 'home_workout_screen.dart' show homeFocusTone;

/// Every movement for one focus, twenty to a page.
///
/// Paged rather than infinitely scrolled on purpose. A page of twenty is a
/// finite thing you can get to the bottom of, which is what someone picking two
/// or three exercises for a session actually needs; an endless list of 106 core
/// movements is a scroll with no end and no decision at the end of it.
///
/// The controls do not scroll away. Refining a filter after reading to the
/// bottom must not mean scrolling all the way back up first.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, required this.focus});

  final HomeFocus focus;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  final _scroll = ScrollController();

  /// Which way the last page change went, so the grid moves along the axis the
  /// user pressed rather than appearing from nowhere.
  bool _forward = true;

  /// The first page earns a stagger. Later pages do not: a cascade every time
  /// you tap "next" turns a page turn into a wait.
  bool _stagger = true;

  @override
  void initState() {
    super.initState();
    // A safety net. The tap that opens this screen sets the focus first, so
    // the first frame is already right; this only fires if the screen was
    // pushed some other way, and it runs after the frame because a notifier
    // cannot be written to while the tree reading it is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(homeFiltersProvider).focus != widget.focus) {
        ref.read(homeFiltersProvider.notifier).open(widget.focus);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final current = ref.read(homeFiltersProvider).page;
    if (page == current) return;
    setState(() {
      _forward = page > current;
      _stagger = false;
    });
    ref.read(homeFiltersProvider.notifier).setPage(page);
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: FDur.slow, curve: FCurve.out);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(homeFiltersProvider);
    final controller = ref.read(homeFiltersProvider.notifier);
    final results = ref.watch(homeResultsProvider);
    final pageItems = ref.watch(homePageProvider);
    final pageCount = ref.watch(homePageCountProvider);
    final page = filters.page.clamp(0, pageCount - 1);
    final tone = homeFocusTone(widget.focus);

    return ColoredBox(
      color: FColors.canvas,
      child: Column(
        children: [
          // -- Header ---------------------------------------------------------
          Padding(
            padding: EdgeInsets.fromLTRB(
              FSpace.gutter,
              MediaQuery.paddingOf(context).top + FSpace.lg,
              FSpace.gutter,
              FSpace.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FIconButton(
                  icon: const FIcon(FIcons.chevronLeft),
                  semanticLabel: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: FSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            margin: const EdgeInsets.only(right: FSpace.sm),
                            decoration: BoxDecoration(
                              color: tone,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              widget.focus.label,
                              style: FType.h1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('At home · ${widget.focus.blurb}',
                          style: FType.small),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -- Controls -------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              0,
              FSpace.gutter,
              FSpace.md,
            ),
            child: Row(
              children: [
                Expanded(child: _SortPill(sort: filters.sort)),
                const SizedBox(width: FSpace.sm),
                _FilterButton(
                  count: filters.activeCount,
                  onTap: () => showFSheet<void>(
                    context: context,
                    builder: (_) => const HomeFilterSheet(),
                  ),
                ),
              ],
            ),
          ),

          // -- Quick kit facets -----------------------------------------------
          // "What can I do holding nothing" is the question this page exists to
          // answer, so it is one tap from the top rather than inside a sheet.
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
              children: [
                for (final need in GearNeed.values) ...[
                  FChip(
                    label: need.label,
                    dense: true,
                    selected: filters.gear.contains(need),
                    onTap: () => controller.toggleGear(need),
                  ),
                  const SizedBox(width: FSpace.sm),
                ],
              ],
            ),
          ),

          // -- Count ----------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              FSpace.lg,
              FSpace.gutter,
              FSpace.md,
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: results.length.toDouble()),
                  duration: FDur.slow,
                  curve: FCurve.out,
                  builder: (context, v, _) => Text(
                    '${v.round()} movement${v.round() == 1 ? '' : 's'}',
                    style: FType.caption,
                  ),
                ),
                if (pageCount > 1) ...[
                  const SizedBox(width: FSpace.sm),
                  Text('·  page ${page + 1} of $pageCount',
                      style: FType.caption.copyWith(color: FColors.textFaint)),
                ],
                const Spacer(),
                if (filters.activeCount > 0)
                  PressFx(
                    onTap: controller.clearFilters,
                    child: Text(
                      'Clear',
                      style: FType.label.copyWith(color: FColors.blue),
                    ),
                  ),
              ],
            ),
          ),

          // -- Grid -----------------------------------------------------------
          Expanded(
            child: results.isEmpty
                ? FEmptyState(
                    icon: FIcons.search,
                    title: 'Nothing left',
                    message: 'Those filters rule out everything here.',
                    action: FButton(
                      label: 'Clear filters',
                      variant: FButtonVariant.secondary,
                      size: FButtonSize.sm,
                      onPressed: controller.clearFilters,
                    ),
                  )
                : FadeEdge(
                    top: 10,
                    bottom: 24,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        FSpace.gutter,
                        0,
                        FSpace.gutter,
                        FSpace.x3l,
                      ),
                      child: Column(
                        children: [
                          // Only when the page is visibly thin. On a full grid
                          // this would be an advert; on a four-card grid it is
                          // the answer to "is this all there is?".
                          if (results.length < 12) ...[
                            const _UnlockNudge(),
                            const SizedBox(height: FSpace.md),
                          ],
                          _PageBody(
                            page: page,
                            items: pageItems,
                            forward: _forward,
                            stagger: _stagger,
                          ),
                          if (pageCount > 1) ...[
                            const SizedBox(height: FSpace.xxl),
                            Pager(
                              page: page,
                              pageCount: pageCount,
                              onChanged: _goToPage,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "One dumbbell would double this page."
///
/// Shown only where it is the honest explanation for a short grid, and it does
/// the thing it suggests rather than sending anyone back a screen to do it.
class _UnlockNudge extends ConsumerWidget {
  const _UnlockNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(homeUnlockSuggestionProvider);
    if (suggestion == null) return const SizedBox.shrink();

    return FCard(
      color: FColors.wash(FColors.blue),
      borderColor: FColors.washBorder(FColors.blue),
      padding: const EdgeInsets.all(FSpace.md),
      onTap: () => ref.read(homeKitProvider.notifier).toggle(suggestion.gear),
      child: Row(
        children: [
          const FIconTile(icon: FIcons.plus, tone: FColors.blue, size: 30),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${suggestion.count} more with '
                  '${suggestion.gear.label.toLowerCase()}',
                  style: FType.h3,
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to add it to your kit. ${suggestion.gear.blurb}.',
                  style: FType.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One page of cards.
///
/// Wrapped in a switcher so a page turn moves along the axis the user pressed:
/// forward comes in from the right, back from the left. Without that, twenty
/// cards silently becoming twenty different cards reads as a glitch.
class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.page,
    required this.items,
    required this.forward,
    required this.stagger,
  });

  /// Identifies the page to the switcher. Deliberately not the widget's own
  /// key: keying this widget would rebuild the switcher itself, and a switcher
  /// that is replaced every time cannot animate anything.
  final int page;
  final List<Exercise> items;
  final bool forward;
  final bool stagger;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        // The image is square and fills the card, so the row height follows the
        // column width. Deriving it beats guessing a ratio that only holds on
        // the phone it was guessed on.
        final cardWidth = (constraints.maxWidth - FSpace.md) / 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: FSpace.md,
            crossAxisSpacing: FSpace.md,
            mainAxisExtent: HomeExerciseCard.extentFor(cardWidth),
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final card = HomeExerciseCard(exercise: items[i]);
            if (!stagger) return card;
            return FadeSlideIn(
              delay: staggerDelay(
                i,
                interval: const Duration(milliseconds: 28),
                maxSteps: 10,
              ),
              offset: 10,
              child: card,
            );
          },
        );
      },
    );

    return AnimatedSwitcher(
      duration: FDur.base,
      switchInCurve: FCurve.out,
      switchOutCurve: FCurve.exit,
      // The two pages overlap during the swap rather than stacking, so the
      // column does not grow to the height of both at once. A short final page
      // means the outgoing one is clipped for 200ms, which is invisible next to
      // the page below it visibly jumping.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previous.map((p) => Positioned.fill(child: p)),
          if (current != null) current,
        ],
      ),
      transitionBuilder: (child, animation) {
        if (reduce) return FadeTransition(opacity: animation, child: child);
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, inner) => Transform.translate(
              offset: Offset(
                (1 - animation.value) * (forward ? 28 : -28),
                0,
              ),
              child: inner,
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(page), child: grid),
    );
  }
}

/// One movement.
///
/// Three facts and a picture, which is exactly what deciding "is this the one"
/// takes: what it looks like, what it is called, what it costs you in kit and
/// in skill.
class HomeExerciseCard extends StatelessWidget {
  const HomeExerciseCard({super.key, required this.exercise});

  final Exercise exercise;

  /// The image is a little wider than tall. A square card put barely two rows
  /// on a phone screen, and the source stills are landscape anyway, so a square
  /// crops the figure harder than this does.
  static const imageRatio = 0.82;

  static const _pad = 8.0;
  static const _nameHeight = 38.0;
  /// The pips are 12 and the caption 14, but a caption's line box rounds up
  /// against the font's own metrics -- hence 16 rather than a tight 14.
  static const _metaHeight = 16.0;

  /// How tall a card is at a given column width. Derived rather than guessed at
  /// a ratio, so a narrow phone shortens the card instead of clipping it.
  static double extentFor(double cardWidth) =>
      (cardWidth - _pad * 2) * imageRatio +
      _pad * 2 +
      FSpace.sm +
      _nameHeight +
      _metaHeight;

  @override
  Widget build(BuildContext context) {
    final gear = exercise.homeGear ?? const <HomeGear>{};
    final kitLabel = gear.isEmpty
        ? 'No kit'
        : gear.map((g) => g.short).join(' + ');

    return FCard(
      padding: const EdgeInsets.all(_pad),
      radius: FRadius.lg,
      onTap: () => Navigator.of(context).push(
        FPageRoute<void>(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseThumb(
              exercise: exercise,
              size: constraints.maxWidth,
              height: constraints.maxWidth * imageRatio,
              radius: FRadius.md,
            ),
            const SizedBox(height: FSpace.sm),
            // Fixed to two lines whether the name needs one or two, so every
            // meta row in the grid sits on the same baseline.
            SizedBox(
              height: _nameHeight,
              child: Text(
                exercise.name,
                style: FType.h3.copyWith(height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                DifficultyPips(level: exercise.difficulty),
                const SizedBox(width: FSpace.sm),
                Expanded(
                  child: Text(
                    kitLabel,
                    style: FType.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Page numbers.
///
/// Numbered rather than a bare next/back pair: the number is what tells you how
/// far in you are and how much is left, and tapping straight to page 4 is the
/// reason to have pages at all.
class Pager extends StatelessWidget {
  const Pager({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  /// A window of numbers around the current page, with the first and last
  /// always reachable. More than about five and they stop being tap targets.
  List<int?> get _slots {
    if (pageCount <= 5) return [for (var i = 0; i < pageCount; i++) i];
    final out = <int?>[0];
    var start = page - 1;
    var end = page + 1;
    if (page <= 2) {
      start = 1;
      end = 3;
    } else if (page >= pageCount - 3) {
      start = pageCount - 4;
      end = pageCount - 2;
    }
    if (start > 1) out.add(null);
    for (var i = start; i <= end; i++) {
      out.add(i);
    }
    if (end < pageCount - 2) out.add(null);
    out.add(pageCount - 1);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Arrow(
          icon: FIcons.chevronLeft,
          semanticLabel: 'Previous page',
          onTap: page > 0 ? () => onChanged(page - 1) : null,
        ),
        const SizedBox(width: FSpace.xs),
        for (final slot in _slots)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: slot == null
                ? SizedBox(
                    width: 18,
                    child: Center(
                      child: Text(
                        '···',
                        style: FType.caption.copyWith(
                          color: FColors.textFaint,
                        ),
                      ),
                    ),
                  )
                : _PageDot(
                    index: slot,
                    selected: slot == page,
                    onTap: () => onChanged(slot),
                  ),
          ),
        const SizedBox(width: FSpace.xs),
        _Arrow(
          icon: FIcons.chevronRight,
          semanticLabel: 'Next page',
          onTap: page < pageCount - 1 ? () => onChanged(page + 1) : null,
        ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Page ${index + 1}',
      child: PressFx(
        onTap: onTap,
        scale: 0.9,
        child: AnimatedContainer(
          duration: FDur.base,
          curve: FCurve.out,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? FColors.primary : FColors.surface,
            borderRadius: FRadius.rMd,
            border: Border.all(
              color: selected ? FColors.primary : FColors.border,
            ),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: FDur.base,
              curve: FCurve.out,
              style: FType.num.copyWith(
                color: selected ? FColors.onPrimary : FColors.textSecondary,
              ),
              child: Text('${index + 1}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final FIconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return FIconButton(
      icon: FIcon(
        icon,
        size: 16,
        color: enabled ? FColors.textSecondary : FColors.textFaint,
      ),
      size: 32,
      semanticLabel: semanticLabel,
      onPressed: onTap,
    );
  }
}

/// Sort, on the surface rather than behind the filter sheet.
///
/// Ordering is not filtering: it is what someone reaches for the instant the
/// grid is not showing what they expected first, and it should cost one tap.
class _SortPill extends StatelessWidget {
  const _SortPill({required this.sort});

  final HomeSort sort;

  @override
  Widget build(BuildContext context) {
    return PressFx(
      onTap: () => showFSheet<void>(
        context: context,
        builder: (_) => const HomeSortSheet(),
      ),
      scale: 0.97,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: FSpace.md),
        decoration: BoxDecoration(
          color: FColors.muted,
          borderRadius: FRadius.rLg,
          border: Border.all(color: FColors.border),
        ),
        child: Row(
          children: [
            const FIcon(FIcons.sort, size: 16, color: FColors.textSecondary),
            const SizedBox(width: FSpace.sm),
            Expanded(
              child: AnimatedSwitcher(
                duration: FDur.fast,
                // A switcher stacks its children centred by default, which
                // quietly pushed the label into the middle of the pill, away
                // from the icon it belongs to.
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                ),
                child: Text(
                  sort.label,
                  key: ValueKey(sort),
                  style: FType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const FIcon(
              FIcons.chevronDown,
              size: 14,
              color: FColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return PressFx(
      onTap: onTap,
      scale: 0.93,
      child: AnimatedContainer(
        duration: FDur.fast,
        curve: FCurve.out,
        height: 46,
        padding: EdgeInsets.symmetric(horizontal: active ? 12 : 14),
        decoration: BoxDecoration(
          color: active ? FColors.wash(FColors.primary) : FColors.muted,
          borderRadius: FRadius.rLg,
          border: Border.all(
            color: active
                ? FColors.primary.withValues(alpha: 0.45)
                : FColors.border,
          ),
        ),
        child: Row(
          children: [
            FIcon(
              FIcons.filter,
              size: 17,
              color: active ? FColors.primary : FColors.textSecondary,
            ),
            AnimatedSize(
              duration: FDur.base,
              curve: FCurve.out,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '$count',
                        style: FType.num.copyWith(color: FColors.primary),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
