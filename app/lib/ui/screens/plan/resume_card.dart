import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/page_transitions.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/session.dart';
import '../../widgets/buttons.dart';
import '../../widgets/indicators.dart';
import '../../widgets/media.dart';
import '../session/session_screen.dart';

/// A workout left running.
///
/// Sits above the week rather than beside it: while a session is live, every
/// "Start" button in the plan is disabled, and a disabled button with no
/// explanation is a dead end on the app's most important control. This is the
/// explanation, and the way back in.
class ResumeCard extends ConsumerWidget {
  const ResumeCard({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = session.progress;

    return Container(
      decoration: BoxDecoration(
        borderRadius: FRadius.rXl,
        border: Border.all(color: FColors.washBorder(FColors.blue)),
        color: FColors.wash(FColors.blue),
      ),
      padding: const EdgeInsets.all(FSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                progress: progress,
                size: 40,
                strokeWidth: 3.5,
                color: FColors.blue,
                trackColor: FColors.washBorder(FColors.blue),
                child: Text(
                  '${(progress * 100).round()}',
                  style: FType.caption.copyWith(color: FColors.blue),
                ),
              ),
              const SizedBox(width: FSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.dayTitle, style: FType.h2),
                    const SizedBox(height: 2),
                    Text(
                      '${session.totalSetsDone} of ${session.totalSetsPlanned} '
                      'sets done',
                      style: FType.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FSpace.xl),
          FButton(
            label: 'Resume workout',
            size: FButtonSize.lg,
            expand: true,
            icon: const FIcon(FIcons.play),
            onPressed: () => Navigator.of(context).push(
              FPageRoute<void>(
                fullscreen: true,
                builder: (_) => const SessionScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
