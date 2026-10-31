import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/auth/domain/auth_service.dart';
import 'package:miga/features/auth/presentation/widgets/auth_code_form.dart';
import 'package:miga/features/auth/presentation/widgets/auth_email_form.dart';
import 'package:miga/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:miga/l10n/app_localizations.dart';

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
  bool _codeHasError = false;
  int _codeErrorCount = 0;
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
          setState(() {
            _error = null;
            _codeHasError = false;
          });
          if (widget.authService?.session != null) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
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
    // Manual actions supersede a verification scheduled by the last digit.
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
      _codeHasError = false;
    });
    try {
      await action(service);
    } on AuthException catch (error, stackTrace) {
      if (error.code == 'sign_in_canceled') return;
      _logAuthFailure(error, stackTrace);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        if (error.code == 'otp_expired') {
          _codeHasError = true;
          _codeErrorCount++;
          _resendTimer?.cancel();
          _resendSeconds = 0;
        }
        _error = switch (error.code) {
          'otp_expired' => l10n.invalidCode,
          'browser_launch_failed' => l10n.authBrowserError,
          'google_not_configured' => l10n.authUnavailable,
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

  // Keep credentials, personal data, and token-bearing URLs out of logs.
  void _logAuthFailure(Object error, StackTrace stackTrace) {
    if (kReleaseMode) return;
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
      _codeHasError = false;
      _codeController.clear();
      _resendSeconds = 0;
    });
  }

  void _onCodeChanged(String value) {
    _codeVerificationTimer?.cancel();
    if (_codeHasError) {
      setState(() {
        _codeHasError = false;
        _error = null;
      });
    }
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
    final session = widget.authService?.session;

    return AuthScaffold(
      formKey: _formKey,
      signedIn: session != null,
      sentTo: _sentTo,
      userEmail: session?.user.email,
      builder: (context, availableWidth) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session != null)
            OutlinedButton(
              onPressed: _busy ? null : () => _run((s) => s.signOut()),
              child: Text(l10n.signOut),
            )
          else if (_sentTo != null)
            AuthCodeForm(
              controller: _codeController,
              busy: _busy,
              hasError: _codeHasError,
              errorCount: _codeErrorCount,
              resendSeconds: _resendSeconds,
              onChanged: _onCodeChanged,
              onVerify: _verifyCode,
              onResend: _sendCode,
              onChangeEmail: _changeEmail,
            )
          else
            AuthEmailForm(
              controller: _emailController,
              busy: _busy,
              availableWidth: availableWidth,
              onSendCode: _sendCode,
              onGoogleSignIn: () => _run(
                (service) => service.signInWithProvider(OAuthProvider.google),
              ),
            ),
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
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    _codeVerificationTimer?.cancel();
    if (_busy || _sentTo == null) return;
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _codeHasError = true;
        _codeErrorCount++;
      });
      return;
    }
    await _run((service) => service.verifyCode(_sentTo!, _codeController.text));
  }
}
