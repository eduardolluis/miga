import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/core/ui/miga_ui_copy.dart';

/// Distinct actions (not duplicates of the bottom navigation).
/// Premium actions always remain tappable so Free users can see Miga Pro.
class HomeDashboardQuickActions extends StatelessWidget {
  const HomeDashboardQuickActions({
    super.key,
    required this.onCookWithPantry,
    required this.onFindCheaper,
    required this.onSurprise,
    required this.onGenerateWeek,
    this.surpriseRemaining = 3,
    this.surpriseBusy = false,
    this.isPro = false,
  });

  final VoidCallback onCookWithPantry;
  final VoidCallback onFindCheaper;
  final VoidCallback onSurprise;
  final VoidCallback onGenerateWeek;
  final int surpriseRemaining;
  final bool surpriseBusy;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final spanish = MigaUiCopy.isSpanish(context);
    return Column(
      key: const ValueKey('home-quick-actions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spanish ? 'Accesos rápidos' : 'Quick actions',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // Keep each action around 134 logical px high on both phones
            // and tablets, while allowing two-line translated labels.
            childAspectRatio: (constraints.maxWidth - 12) / (2 * 134),
            children: [
              _ShortcutCard(
                key: const ValueKey('home-quick-pantry'),
                icon: Icons.kitchen_outlined,
                title: spanish ? '¿Qué puedo cocinar?' : 'What can I cook?',
                subtitle: spanish ? 'Con lo que ya tienes' : 'Use your pantry',
                onTap: onCookWithPantry,
              ),
              _ShortcutCard(
                key: const ValueKey('home-quick-cheaper'),
                icon: Icons.savings_outlined,
                title: spanish
                    ? 'Alternativas económicas'
                    : 'Find cheaper alternatives',
                subtitle: spanish
                    ? 'Sustituye ingredientes'
                    : 'Save on ingredients',
                proBadge: !isPro,
                onTap: onFindCheaper,
              ),
              _ShortcutCard(
                key: const ValueKey('home-quick-surprise'),
                icon: Icons.casino_outlined,
                title: spanish ? 'Sorpréndeme' : 'Surprise me',
                subtitle: isPro
                    ? (spanish ? 'Sin límites' : 'Unlimited')
                    : (spanish
                          ? '$surpriseRemaining de 3 usos gratis'
                          : '$surpriseRemaining of 3 free uses left'),
                proBadge: !isPro && surpriseRemaining == 0,
                busy: surpriseBusy,
                onTap: onSurprise,
              ),
              _ShortcutCard(
                key: const ValueKey('home-quick-generate'),
                icon: Icons.auto_awesome_outlined,
                title: spanish ? 'Generar mi semana' : 'Generate my week',
                subtitle: spanish ? 'Menú automático' : 'Automatic meal plan',
                proBadge: !isPro,
                onTap: onGenerateWeek,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.proBadge = false,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool proBadge;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8EFDA),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox(
                      height: 26,
                      width: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    Icon(icon, size: 29, color: AppColors.olive),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.12,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              if (proBadge)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFFFE3A3),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          color: Color(0xFF754D04),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
