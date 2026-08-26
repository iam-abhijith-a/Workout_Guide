import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/page_transitions.dart';
import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/guides.dart';
import '../../../state/providers.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/chips.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';
import '../root_screen.dart';
import 'guide_screen.dart';

/// Learn.
///
/// The part of a fitness app that usually does not exist. Everything here
/// answers a question a beginner is too self-conscious to ask out loud, which is
/// exactly why it needs to be in the app rather than in a forum.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    // A first-timer needs the first-session guide above everything else; someone
    // twenty sessions in does not.
    final featured = history.isEmpty
        ? guideById('first-session')
        : guideById('progressive-overload');
    final rest = guides.where((g) => g.id != featured?.id).toList();

    return FScreen(
      title: 'Learn',
      subtitle: 'What nobody tells you before your first session',
      bottomPadding: kTabBarInset + FSpace.xxl,
      slivers: [
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FSpace.gutter,
                0,
                FSpace.gutter,
                FSpace.xl,
              ),
              child: FadeSlideIn(child: _FeaturedCard(guide: featured)),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          sliver: SliverList.separated(
            itemCount: rest.length,
            separatorBuilder: (_, __) => const SizedBox(height: FSpace.sm),
            itemBuilder: (context, i) => FadeSlideIn(
              delay: staggerDelay(
                i,
                baseDelay: const Duration(milliseconds: 60),
              ),
              child: _GuideRow(guide: rest[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    return FCard(
      padding: const EdgeInsets.all(FSpace.xl),
      color: FColors.canvas,
      borderColor: FColors.borderStrong,
      elevated: true,
      onTap: () => Navigator.of(
        context,
      ).push(FPageRoute<void>(builder: (_) => GuideScreen(guideId: guide.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FIconTile(icon: guide.icon, tone: guide.tone, size: 40),
              const SizedBox(width: FSpace.md),
              FTag(label: guide.tag, tone: guide.tone),
              const Spacer(),
              Text('${guide.minutes} min', style: FType.caption),
            ],
          ),
          const SizedBox(height: FSpace.lg),
          Text(guide.title, style: FType.h1),
          const SizedBox(height: FSpace.xs),
          Text(guide.summary, style: FType.body),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    return FCard(
      onTap: () => Navigator.of(
        context,
      ).push(FPageRoute<void>(builder: (_) => GuideScreen(guideId: guide.id))),
      child: Row(
        children: [
          FIconTile(icon: guide.icon, tone: guide.tone, size: 36),
          const SizedBox(width: FSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guide.title, style: FType.h3),
                const SizedBox(height: 2),
                Text(
                  guide.summary,
                  style: FType.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: FSpace.md),
          Text('${guide.minutes} min', style: FType.caption),
          const SizedBox(width: FSpace.sm),
          const FIcon(FIcons.chevronRight, size: 15, color: FColors.textFaint),
        ],
      ),
    );
  }
}
