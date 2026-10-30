import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'auth_form_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.formKey,
    required this.signedIn,
    required this.sentTo,
    required this.userEmail,
    required this.builder,
  });

  final GlobalKey<FormState> formKey;
  final bool signedIn;
  final String? sentTo;
  final String? userEmail;
  final Widget Function(BuildContext context, double availableWidth) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1710),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/onboarding/welcome.png',
              fit: BoxFit.cover,
              alignment: const Alignment(-0.1, 0.35),
              excludeFromSemantics: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x000E1710),
                    Color(0x800E1710),
                    Color(0xD90E1710),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Theme(
                      data: buildAuthFormTheme(theme),
                      child: Form(
                        key: formKey,
                        child: CustomScrollView(
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  36,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _AuthBrand(showBack: !signedIn),
                                    const Spacer(flex: 2),
                                    const SizedBox(height: 32),
                                    _AuthHeading(
                                      signedIn: signedIn,
                                      sentTo: sentTo,
                                      userEmail: userEmail,
                                    ),
                                    const SizedBox(height: 28),
                                    builder(context, constraints.maxWidth - 48),
                                    const SizedBox(height: 24),
                                    Text(
                                      l10n.onboardingIntro,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                            height: 1.5,
                                          ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack && Navigator.of(context).canPop()) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const BackButton(color: Colors.white),
          ),
          const SizedBox(width: 14),
        ],
        const Icon(Icons.eco_rounded, color: Colors.white, size: 25),
        const SizedBox(width: 8),
        Text(
          'miga',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _AuthHeading extends StatelessWidget {
  const _AuthHeading({
    required this.signedIn,
    required this.sentTo,
    required this.userEmail,
  });

  final bool signedIn;
  final String? sentTo;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final email = sentTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          signedIn
              ? l10n.authSuccess
              : email != null
              ? l10n.checkEmail
              : l10n.authTitle,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 38,
            height: 1.1,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          email != null && !signedIn
              ? TextSpan(
                  children: [
                    TextSpan(
                      text: l10n
                          .codeSentTo(email)
                          .split(email)
                          .first
                          .trimRight(),
                    ),
                    TextSpan(
                      text: '\n$email',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : TextSpan(text: signedIn ? userEmail ?? '' : l10n.authSubtitle),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
