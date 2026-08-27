import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/media.dart';
import 'home_workout/home_workout_screen.dart';
import 'library/library_screen.dart';
import 'learn/learn_screen.dart';
import 'plan/plan_screen.dart';
import 'progress/progress_screen.dart';

/// The tabbed shell.
///
/// Five destinations, each named for what is actually inside it. "At home",
/// "Plan", "Library" tell you what you will find; "Home" and "More" would not.
///
/// "At home" leads because it is the tab that works on any given evening,
/// whether or not the plan is being followed that week. What used to sit here
/// -- a Today page whose job was to show the next planned session and start it
/// -- now lives at the top of Plan, next to the week it belongs to.
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _index = 0;

  // Kept alive across tab switches so scroll position and filter state survive
  // navigation -- losing your place in a 1,324-item library is infuriating.
  final _pages = const [
    HomeWorkoutScreen(),
    PlanScreen(),
    LibraryScreen(),
    ProgressScreen(),
    LearnScreen(),
  ];

  static const _tabs = <({FIconData icon, String label})>[
    (icon: FIcons.home, label: 'At home'),
    (icon: FIcons.calendar, label: 'Plan'),
    (icon: FIcons.search, label: 'Library'),
    (icon: FIcons.chart, label: 'Progress'),
    (icon: FIcons.book, label: 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    return FBackdrop(
      child: Column(
        children: [
          Expanded(
            child: FadeIndexedStack(index: _index, children: _pages),
          ),
          FTabBar(
            index: _index,
            tabs: _tabs,
            onChanged: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

/// Fills the space behind the tab bar so the last item in any list is not
/// trapped under the floating chrome.
const kTabBarInset = 78.0;

/// Shared page background tint.
const kPageTint = FColors.primary;
