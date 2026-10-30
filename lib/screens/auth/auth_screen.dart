import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../widgets/verification_code_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  StreamSubscription<AuthState>? _subscription;
  Timer? _resendTimer;
  Timer? _codeVerificationTimer;
  String? _sentTo;
  String? _error;
  bool _busy = false;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.authService?.changes.listen(
      (state) {
        if (!mounted) return;
        if (state.event == AuthChangeEvent.signedOut) {
          _changeEmail();
        } else {
          setState(() => _error = null);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _logAuthFailure(error, stackTrace);
        if (mounted) {
          setState(() => _error = AppLocalizations.of(context)!.authError);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _resendTimer?.cancel();
    _codeVerificationTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthService) action) async {
    _codeVerificationTimer?.cancel();
    if (_busy) return;
    final service = widget.authService;
    if (service == null) {
      setState(() => _error = AppLocalizations.of(context)!.authUnavailable);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(service);
    } on AuthException catch (error, stackTrace) {
      _logAuthFailure(error, stackTrace);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = switch (error.code) {
          'otp_expired' => l10n.invalidCode,
          'browser_launch_failed' => l10n.authBrowserError,
          'over_email_send_rate_limit' ||
          'over_request_rate_limit' => l10n.authRateLimited,
          _ => l10n.authError,
        };
      });
    } catch (error, stackTrace) {
      _logAuthFailure(error, stackTrace);
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.authError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Log diagnostic metadata in development without logging credentials,
  // email addresses, codes, or callback URLs that may contain tokens.
  void _logAuthFailure(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    final details = switch (error) {
      AuthException e => 'code=${e.code}, status=${e.statusCode}',
      PlatformException e => 'code=${e.code}',
      _ => 'no error code',
    };
    debugPrint('[Miga auth] ${error.runtimeType}: $details');
    debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendSeconds--);
      if (_resendSeconds == 0) timer.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (_sentTo == null && !_formKey.currentState!.validate()) return;
    final email = _sentTo ?? _emailController.text.trim();
    final languageCode = Localizations.localeOf(context).languageCode;
    await _run((service) async {
      await service.sendCode(email, languageCode: languageCode);
      if (!mounted) return;
      setState(() {
        _sentTo = email;
        _codeController.clear();
        _startResendCooldown();
      });
    });
  }

  void _changeEmail() {
    _resendTimer?.cancel();
    _codeVerificationTimer?.cancel();
    setState(() {
      _sentTo = null;
      _error = null;
      _codeController.clear();
      _resendSeconds = 0;
    });
  }

  void _onCodeChanged(String value) {
    _codeVerificationTimer?.cancel();
    if (value.length == 6) {
      _codeVerificationTimer = Timer(
        const Duration(milliseconds: 500),
        _verifyCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = widget.authService?.session;
    final enteringCode = _sentTo != null;

    final formTheme = theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xB3202A1F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
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
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xB3202A1F),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white60, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );

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
                      data: formTheme,
                      child: Form(
                        key: _formKey,
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
                                    Row(
                                      children: [
                                        if (Navigator.of(context).canPop()) ...[
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white24,
                                              ),
                                            ),
                                            child: const BackButton(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                        ],
                                        const Icon(
                                          Icons.eco_rounded,
                                          color: Colors.white,
                                          size: 25,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'miga',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -1,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(flex: 2),
                                    const SizedBox(height: 32),
                                    Text(
                                      session != null
                                          ? l10n.authSuccess
                                          : enteringCode
                                          ? l10n.checkEmail
                                          : l10n.authTitle,
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            fontSize: 38,
                                            height: 1.1,
                                            letterSpacing: -1.2,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black26,
                                                blurRadius: 12,
                                              ),
                                            ],
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text.rich(
                                      enteringCode && session == null
                                          ? TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: l10n
                                                      .codeSentTo(_sentTo!)
                                                      .split(_sentTo!)
                                                      .first
                                                      .trimRight(),
                                                ),
                                                TextSpan(
                                                  text: '\n${_sentTo!}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : TextSpan(
                                              text: session != null
                                                  ? session.user.email ?? ''
                                                  : l10n.authSubtitle,
                                            ),
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
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
                                    const SizedBox(height: 28),
                                    ..._buildFormContent(
                                      context,
                                      constraints.maxWidth - 48,
                                    ),
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

  List<Widget> _buildFormContent(BuildContext context, double availableWidth) {
    final l10n = AppLocalizations.of(context)!;
    final session = widget.authService?.session;
    final enteringCode = _sentTo != null;
    final showApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    const olive = Color(0xFF52643D);
    return [
      if (session != null)
        OutlinedButton(
          onPressed: _busy ? null : () => _run((s) => s.signOut()),
          child: Text(l10n.signOut),
        )
      else ...[
        if (!enteringCode) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFF2F2F2),
              side: const BorderSide(color: Color(0xFF747775)),
              foregroundColor: const Color(0xFF1F1F1F),
              disabledForegroundColor: const Color(0xFF8E918F),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: _busy
                ? null
                : () => _run((s) => s.signInWithProvider(OAuthProvider.google)),
            icon: SvgPicture.asset(
              'assets/google.svg',
              width: 20,
              height: 20,
              excludeFromSemantics: true,
            ),
            label: Text(l10n.continueWithGoogle),
          ),
          if (showApple) ...[
            const SizedBox(height: 12),
            // TODO: Completar la integración de Sign in with Apple al final.
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF747775)),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy
                  ? null
                  : () {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.appleSignInUnavailable),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              icon: const Icon(Icons.apple),
              label: Text(l10n.continueWithApple),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF9BA197))),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: availableWidth * 0.6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.orWithEmail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFEBEEE7)),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFF9BA197))),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const ValueKey('email'),
            cursorColor: Colors.white,
            controller: _emailController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendCode(),
            decoration: InputDecoration(
              hintText: l10n.email,
              hintStyle: const TextStyle(color: Colors.white),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return l10n.emailRequired;
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return l10n.emailInvalid;
              }
              return null;
            },
          ),
        ] else ...[
          VerificationCodeField(
            key: const ValueKey('code'),
            controller: _codeController,
            enabled: !_busy,
            label: l10n.emailCode,
            errorText: l10n.codeRequired,
            onChanged: _onCodeChanged,
            onSubmitted: _verifyCode,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: olive,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: const Size.fromHeight(58),
          ),
          onPressed: _busy
              ? null
              : enteringCode
              ? _verifyCode
              : _sendCode,
          child: Text(enteringCode ? l10n.verifyCode : l10n.emailMeCode),
        ),
        if (enteringCode) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy || _resendSeconds > 0 ? null : _sendCode,
            child: Text(
              _resendSeconds > 0
                  ? l10n.resendIn(_resendSeconds)
                  : l10n.resendCode,
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _changeEmail,
            child: Text(l10n.changeEmail),
          ),
        ],
      ],
      if (_busy) ...[
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ],
      if (_error != null) ...[
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFC7BE)),
          ),
        ),
      ],
    ];
  }

  Future<void> _verifyCode() async {
    _codeVerificationTimer?.cancel();
    if (_busy || _sentTo == null) return;
    if (!_formKey.currentState!.validate()) return;
    await _run((service) => service.verifyCode(_sentTo!, _codeController.text));
  }
}
