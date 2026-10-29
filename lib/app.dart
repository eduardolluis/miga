import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';

import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MigaApp extends StatelessWidget {
  const MigaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miga',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E72)),
      ),
      home: const OnboardingScreen(),
    );
  }
}
