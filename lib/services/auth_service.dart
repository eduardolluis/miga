import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_ios/google_sign_in_ios.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as platform;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps Supabase calls separate from the form so the flow can be tested.
abstract class AuthService {
  Session? get session;
  Stream<AuthState> get changes;
  Future<void> sendCode(String email, {required String languageCode});
  Future<void> verifyCode(String email, String code);
  Future<void> signInWithProvider(OAuthProvider provider);
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(
    this.client, {
    this.googleWebClientId = const String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
    ),
    this.googleIosClientId = const String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
    ),
    this.iosGoogleFactory = GoogleSignInIOS.new,
  });

  final SupabaseClient client;
  final String googleWebClientId;
  final String googleIosClientId;
  final platform.GoogleSignInPlatform Function() iosGoogleFactory;
  static platform.GoogleSignInPlatform? _iosGoogle;
  static bool _googleSignInPending = false;
  // GoogleSignIn is a singleton and must be initialized exactly once. Keep
  // initialization lazy so missing Google configuration doesn't block email.
  static Future<void>? _googleInitialization;
  static const redirectUrl = 'com.eduardodelacruz.miga://login-callback';

  // Fixed labels and error codes only: never print tokens or account details.
  Future<T> _googleStep<T>(String step, Future<T> Function() action) async {
    final timer = Stopwatch()..start();
    if (!kReleaseMode) debugPrint('[Miga auth] Google step=$step started');
    try {
      final result = await action();
      if (!kReleaseMode) {
        debugPrint(
          '[Miga auth] Google step=$step completed ms=${timer.elapsedMilliseconds}',
        );
      }
      return result;
    } catch (error) {
      if (!kReleaseMode) {
        final code = switch (error) {
          GoogleSignInException e => e.code.name,
          AuthException e => e.code ?? 'unknown',
          _ => error.runtimeType.toString(),
        };
        final reason = error is AuthException
            ? error.message.toLowerCase()
            : '';
        final hint = reason.contains('nonce')
            ? 'nonce_configuration'
            : reason.contains('audience') || reason.contains('audiences')
            ? 'client_id_configuration'
            : 'none';
        debugPrint(
          '[Miga auth] Google step=$step failed code=$code hint=$hint ms=${timer.elapsedMilliseconds}',
        );
      }
      rethrow;
    }
  }

  bool get _usesNativeGoogle =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Session? get session => client.auth.currentSession;

  @override
  Stream<AuthState> get changes => client.auth.onAuthStateChange;

  @override
  Future<void> sendCode(String email, {required String languageCode}) {
    final language = languageCode == 'es' ? 'es' : 'en';
    // Existing accounts don't get new metadata from an unauthenticated OTP
    // request. The mobile redirect also carries this request's language.
    final emailRedirect = Uri.parse(kIsWeb ? Uri.base.origin : redirectUrl)
        .replace(queryParameters: {'language': language});
    return client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      data: {'language': language},
      emailRedirectTo: emailRedirect.toString(),
    );
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    final response = await client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    if (response.session == null) {
      throw const AuthException('No session returned');
    }
  }

  @override
  Future<void> signInWithProvider(OAuthProvider provider) async {
    if (provider == OAuthProvider.google && _usesNativeGoogle) {
      await _signInWithGoogle();
      return;
    }
    final launched = await client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? Uri.base.origin : redirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    // Opening the browser isn't a successful login. The session arrives later
    // through onAuthStateChange after Supabase handles the callback.
    if (!launched) {
      throw const AuthException(
        'Could not open sign-in',
        code: 'browser_launch_failed',
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (googleWebClientId.trim().isEmpty ||
        (isIos && googleIosClientId.trim().isEmpty)) {
      throw const AuthException(
        'Missing native Google client IDs',
        code: 'google_not_configured',
      );
    }

    // Native Google configuration is shared. Don't let another attempt replace
    // the nonce while the current one is presenting UI or exchanging tokens.
    if (_googleSignInPending) {
      throw const AuthException(
        'Google sign-in is already in progress',
        code: 'sign_in_in_progress',
      );
    }
    _googleSignInPending = true;

    final google = GoogleSignIn.instance;
    try {
      if (isIos) {
        await _signInWithIosGoogle();
        return;
      }
      await _googleStep(
        'initialize',
        () => _googleInitialization ??= google.initialize(
          serverClientId: googleWebClientId,
        ),
      );
      // Clear any SDK account left by a previous attempt, including attempts
      // where Google succeeded but the Supabase token exchange failed.
      await _googleStep('clear_previous_account', google.signOut);
      final account = await _googleStep(
        'choose_account',
        () => google.authenticate(scopeHint: ['email']),
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google returned no ID token');
      }
      final authorization = await _googleStep(
        'authorize_email',
        () async =>
            await account.authorizationClient.authorizationForScopes([
              'email',
            ]) ??
            await account.authorizationClient.authorizeScopes(['email']),
      );
      final response = await _googleStep(
        'supabase_session',
        () => client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: authorization.accessToken,
        ),
      );
      if (response.session == null) {
        throw const AuthException('No session returned');
      }
    } on GoogleSignInException catch (error) {
      throw AuthException(
        'Native Google sign-in failed',
        code: switch (error.code) {
          GoogleSignInExceptionCode.canceled => 'sign_in_canceled',
          GoogleSignInExceptionCode.clientConfigurationError ||
          GoogleSignInExceptionCode.providerConfigurationError =>
            'google_not_configured',
          _ => 'google_sign_in_failed',
        },
      );
    } finally {
      _googleSignInPending = false;
    }
  }

  Future<void> _signInWithIosGoogle() async {
    final random = Random.secure();
    final rawNonce = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // google_sign_in 7's singleton accepts a nonce only at initialization,
    // which must happen once. Use the official iOS adapter directly with a new
    // instance per attempt, initialized once with this attempt's nonce.
    // Supabase remains the source of session/auth events for the app.
    final google = iosGoogleFactory();
    await _googleStep(
      'initialize',
      () => google.init(
        platform.InitParameters(
          clientId: googleIosClientId,
          serverClientId: googleWebClientId,
          nonce: hashedNonce,
        ),
      ),
    );
    _iosGoogle = google;
    await _googleStep(
      'clear_previous_account',
      () => google.signOut(const platform.SignOutParams()),
    );
    final account = await _googleStep(
      'choose_account',
      () => google.authenticate(
        const platform.AuthenticateParameters(scopeHint: ['email']),
      ),
    );
    final idToken = account.authenticationTokens.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Google returned no ID token');
    }
    Future<platform.ClientAuthorizationTokenData?> authorize(bool prompt) =>
        google.clientAuthorizationTokensForScopes(
          platform.ClientAuthorizationTokensForScopesParameters(
            request: platform.AuthorizationRequestDetails(
              scopes: const ['email'],
              userId: account.user.id,
              email: account.user.email,
              promptIfUnauthorized: prompt,
            ),
          ),
        );
    final authorization = await _googleStep(
      'authorize_email',
      () async => await authorize(false) ?? await authorize(true),
    );
    final response = await _googleStep(
      'supabase_session',
      () => client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization?.accessToken,
        nonce: rawNonce,
      ),
    );
    if (response.session == null) {
      throw const AuthException('No session returned');
    }
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        _iosGoogle != null) {
      await _iosGoogle!.signOut(const platform.SignOutParams());
      return;
    }
    if (_usesNativeGoogle && _googleInitialization != null) {
      await _googleInitialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}
