import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  });

  final SupabaseClient client;
  final String googleWebClientId;
  final String googleIosClientId;
  // GoogleSignIn is a singleton and must be initialized exactly once. Keep
  // initialization lazy so missing Google configuration doesn't block email.
  static Future<void>? _googleInitialization;
  static const redirectUrl = 'com.eduardodelacruz.miga://login-callback';

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

    final google = GoogleSignIn.instance;
    try {
      await (_googleInitialization ??= google.initialize(
        clientId: isIos ? googleIosClientId : null,
        serverClientId: googleWebClientId,
      ));
      // Clear any SDK account left by a previous attempt, including attempts
      // where Google succeeded but the Supabase token exchange failed.
      await google.signOut();
      final account = await google.authenticate(scopeHint: ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google returned no ID token');
      }
      final authorization =
          await account.authorizationClient.authorizationForScopes(['email']) ??
          await account.authorizationClient.authorizeScopes(['email']);
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
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
    }
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
    if (_usesNativeGoogle && _googleInitialization != null) {
      await _googleInitialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}
