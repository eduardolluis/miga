import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E72)),
  );

  static ThemeData household(ThemeData base) => base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.olive,
      onPrimary: Colors.white,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.cream,
      indicatorColor: Color(0xFFE4E8D8),
      elevation: 0,
    ),
  );
}
