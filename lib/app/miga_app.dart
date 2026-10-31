import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:miga/app/navigation/app_shell.dart';
import 'package:miga/core/theme/app_theme.dart';
import 'package:miga/features/auth/domain/auth_service.dart';
import 'package:miga/features/onboarding/presentation/onboarding_screen.dart';
import 'package:miga/l10n/app_localizations.dart';

class MigaApp extends StatefulWidget {
  const MigaApp({super.key, this.authService, this.client});

  final AuthService? authService;
  final SupabaseClient? client;
  @override
  State<MigaApp> createState() => _MigaAppState();
}

class _MigaAppState extends State<MigaApp> {
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miga',
      locale: _locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      home: StreamBuilder<AuthState>(
        stream: widget.authService?.changes,
        builder: (context, _) => widget.authService?.session != null
            ? AppShell(
                key: ValueKey(widget.authService!.session!.user.id),
                authService: widget.authService,
                client: widget.client,
                enablePriceEstimates: widget.client != null,
                onLanguageChanged: (language) {
                  final locale = language == null ? null : Locale(language);
                  if (_locale != locale) setState(() => _locale = locale);
                },
              )
            : OnboardingScreen(authService: widget.authService),
      ),
    );
  }
}
