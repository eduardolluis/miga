import 'package:flutter/foundation.dart';
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
  SupabaseAuthService(this.client);

  final SupabaseClient client;
  static const redirectUrl = 'com.eduardodelacruz.miga://login-callback';

  @override
  Session? get session => client.auth.currentSession;

  @override
  Stream<AuthState> get changes => client.auth.onAuthStateChange;

  @override
  Future<void> sendCode(String email, {required String languageCode}) {
    final language = languageCode == 'es' ? 'es' : 'en';
    // Existing accounts don't get new metadata from an unauthenticated OTP
    // request. The mobile redirect also carries this request's language.
    final emailRedirect = Uri.parse(
      kIsWeb ? Uri.base.origin : redirectUrl,
    ).replace(queryParameters: {'language': language});
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

  @override
  Future<void> signOut() => client.auth.signOut();
}
