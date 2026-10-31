import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/features/auth/domain/auth_service.dart';
import 'package:miga/features/onboarding/presentation/onboarding_screen.dart';
import 'package:miga/l10n/app_localizations.dart';

class MigaApp extends StatelessWidget {
  const MigaApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miga',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      home: StreamBuilder<AuthState>(
        stream: authService?.changes,
        builder: (context, _) => authService?.session != null
            ? AppShell(
                key: ValueKey(authService!.session!.user.id),
                authService: authService,
              )
            : OnboardingScreen(authService: authService),
      ),
    );
  }
}
