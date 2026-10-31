import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:miga/features/auth/domain/auth_service.dart';

class FakeAuthService implements AuthService {
  final events = StreamController<AuthState>.broadcast();
  @override
  Session? session;
  String? sentEmail;
  String? sentLanguage;
  String? verifiedEmail;
  String? verifiedCode;
  int verifyCalls = 0;
  OAuthProvider? provider;
  AuthException? sendError;
  AuthException? verifyError;
  AuthException? providerError;
  Completer<void>? sendPending;
  Completer<void>? providerPending;

  @override
  Stream<AuthState> get changes => events.stream;

  @override
  Future<void> sendCode(String email, {required String languageCode}) async {
    sentLanguage = languageCode;
    sentEmail = email;
    if (sendError != null) throw sendError!;
    if (sendPending != null) await sendPending!.future;
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    verifyCalls++;
    verifiedEmail = email;
    verifiedCode = code;
    if (verifyError != null) throw verifyError!;
    session = Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      user: User(
        id: 'test-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-29T00:00:00Z',
        email: email,
      ),
    );
    events.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  @override
  Future<void> signInWithProvider(OAuthProvider provider) async {
    this.provider = provider;
    if (providerPending != null) await providerPending!.future;
    if (providerError != null) throw providerError!;
  }

  @override
  Future<void> signOut() async {
    session = null;
    events.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}
