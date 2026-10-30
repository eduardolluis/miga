import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

ThemeData buildAuthFormTheme(ThemeData theme) {
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(error: AppColors.error),
    inputDecorationTheme: InputDecorationTheme(
      errorMaxLines: 3,
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
        height: 1.5,
      ),
      filled: true,
      fillColor: const Color(0xB3202A1F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white60, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white60, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xB3202A1F),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white60, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.42),
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
