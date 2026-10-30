import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'services/auth_service.dart';

import 'l10n/app_localizations.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

class MigaApp extends StatelessWidget {
  const MigaApp({super.key, this.authService});

  final AuthService? authService;

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
      home: StreamBuilder<AuthState>(
        stream: authService?.changes,
        builder: (context, snapshot) => authService?.session != null
            ? AuthScreen(authService: authService)
            : OnboardingScreen(authService: authService),
      ),
    );
  }
}
