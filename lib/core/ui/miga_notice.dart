import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';

void showMigaNotice(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      // SnackBars with actions otherwise stay open indefinitely in Material 3.
      persist: false,
      behavior: SnackBarBehavior.floating,
      backgroundColor: error
          ? const Color(0xFFFFF1EC)
          : const Color(0xFFEAF1E3),
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: error ? const Color(0xFFE8C4BB) : const Color(0xFFD5E2CC),
        ),
      ),
      action: action,
      dismissDirection: DismissDirection.horizontal,
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: error ? AppColors.error : AppColors.olive,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
    snackBarAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 240),
            reverseDuration: Duration(milliseconds: 180),
          ),
  );
}
