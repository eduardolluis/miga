import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthService {
  Session? get session;
  Stream<AuthState> get changes;
  Future<void> sendCode(String email, {required String languageCode});
  Future<void> verifyCode(String email, String code);

  /// OAuth can finish after this returns; observe [changes] for the session.
  Future<void> signInWithProvider(OAuthProvider provider);

  Future<void> signOut();
}
