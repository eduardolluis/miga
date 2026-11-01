import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/home/application/home_controller.dart';
import 'package:miga/l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.controller,
    required this.onGroceries,
  });
  final HomeController controller;
  final VoidCallback onGroceries;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: Text(l.notificationsTitle),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final count = controller.pendingGroceries;
            if (count == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.olive,
                        size: 46,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l.notificationsEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.notificationsEmptyNote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Material(
                  color: const Color(0xFFFEFDF9),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    leading: const Icon(
                      Icons.shopping_basket_outlined,
                      color: AppColors.olive,
                    ),
                    title: Text(
                      l.homeGroceryList,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(l.homeGroceryCount(count)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: onGroceries,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
