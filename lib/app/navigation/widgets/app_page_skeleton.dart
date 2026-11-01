import 'package:flutter/material.dart';
import 'package:miga/app/navigation/app_tab.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';

/// Matches each tab's main blocks while household data is being restored.
class AppPageSkeleton extends StatelessWidget {
  const AppPageSkeleton({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) => Semantics(
    label: MigaUiCopy.choose(context, 'Cargando contenido', 'Loading content'),
    liveRegion: true,
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MigaSkeleton(child: SkeletonBox(width: 145, height: 32)),
          const SizedBox(height: 24),
          if (tab == AppTab.home) ...[
            const MigaSkeleton(child: SkeletonBox(height: 194, radius: 24)),
            const SizedBox(height: 28),
            const MigaSkeleton(child: SkeletonBox(width: 110, height: 24)),
            const SkeletonRows(count: 1),
            const SizedBox(height: 26),
            const MigaSkeleton(child: SkeletonBox(width: 210, height: 24)),
            const SizedBox(height: 16),
            const SkeletonRecipeCards(),
          ] else if (tab == AppTab.recipes) ...[
            const MigaSkeleton(child: SkeletonBox(height: 48, radius: 26)),
            const SizedBox(height: 16),
            const MigaSkeleton(
              child: Row(
                children: [
                  Expanded(child: SkeletonBox(height: 36, radius: 18)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 36, radius: 18)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 36, radius: 18)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SkeletonRecipeCards(),
            const SizedBox(height: 12),
            const SkeletonRecipeCards(),
          ] else if (tab == AppTab.plan) ...[
            const MigaSkeleton(child: SkeletonBox(height: 14)),
            const SizedBox(height: 28),
            for (var i = 0; i < 2; i++) ...[
              const MigaSkeleton(child: SkeletonBox(width: 180, height: 24)),
              const SkeletonRows(),
              const SizedBox(height: 20),
            ],
          ] else if (tab == AppTab.profile) ...[
            const MigaSkeleton(
              child: SkeletonBox(width: 72, height: 72, radius: 36),
            ),
            const SizedBox(height: 24),
            const SkeletonRows(count: 6),
          ] else ...[
            const MigaSkeleton(child: SkeletonBox(height: 100, radius: 20)),
            const SizedBox(height: 24),
            const SkeletonRows(count: 6),
          ],
        ],
      ),
    ),
  );
}
