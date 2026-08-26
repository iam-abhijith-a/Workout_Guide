import 'package:flutter/widgets.dart';

import '../../../core/motion/widgets.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/content/guides.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/buttons.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';

/// A single guide.
///
/// Reading layout, not app layout: a narrower measure, looser leading, and real
/// space between sections. Dense UI text is fine for a set row and terrible for
/// four minutes of prose.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context) {
    final guide = guideById(guideId);

    if (guide == null) {
      return FScreen(
        title: 'Not found',
        leading: FIconButton(
          icon: const FIcon(FIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FEmptyState(
              title: 'Guide unavailable',
              message: 'This article is no longer part of the app.',
            ),
          ),
        ],
      );
    }

    return FScreen(
      title: guide.title,
      subtitle: '${guide.minutes} min read',
      leading: FIconButton(
        icon: const FIcon(FIcons.chevronLeft),
        semanticLabel: 'Back',
        onPressed: () => Navigator.of(context).pop(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              0,
              FSpace.gutter,
              FSpace.x3l,
            ),
            child: FadeSlideIn(
              child: Text(
                guide.summary,
                style: FType.h2.copyWith(
                  color: FColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: FSpace.gutter),
          sliver: SliverList.builder(
            itemCount: guide.sections.length,
            itemBuilder: (context, i) => FadeSlideIn(
              delay: staggerDelay(
                i,
                baseDelay: const Duration(milliseconds: 60),
              ),
              child: _Section(
                section: guide.sections[i],
                tone: guide.tone,
                isLast: i == guide.sections.length - 1,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FSpace.gutter,
              FSpace.xxl,
              FSpace.gutter,
              0,
            ),
            child: FButton(
              label: 'Back to Learn',
              variant: FButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.tone,
    required this.isLast,
  });

  final GuideSection section;

  /// The guide's colour, carried down to the section rule and the callout so
  /// an article reads as one piece rather than a stack of grey boxes.
  final Color tone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : FSpace.x3l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9, right: FSpace.md),
                width: 16,
                height: 2.5,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: Text(section.heading, style: FType.h2)),
            ],
          ),
          const SizedBox(height: FSpace.lg),

          for (final paragraph in section.body)
            Padding(
              padding: const EdgeInsets.only(bottom: FSpace.lg),
              child: Text(
                paragraph,
                style: FType.body.copyWith(
                  color: FColors.textSecondary,
                  height: 1.65,
                ),
              ),
            ),

          if (section.callout != null) ...[
            const SizedBox(height: FSpace.xs),
            FCard(
              color: FColors.wash(tone),
              borderColor: FColors.washBorder(tone),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FIcon(FIcons.sparkle, size: 15, color: tone),
                  ),
                  const SizedBox(width: FSpace.md),
                  Expanded(
                    child: Text(
                      section.callout!,
                      style: FType.small.copyWith(
                        color: FColors.text,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
