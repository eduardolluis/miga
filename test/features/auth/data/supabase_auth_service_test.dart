import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:miga/features/auth/data/supabase_auth_service.dart';

class FakeGooglePlatform extends GoogleSignInPlatform {
  InitParameters? initialization;
  int initializeCalls = 0;
  int signOutCalls = 0;
  String? idToken = 'google-id-token';
  GoogleSignInException? error;
  bool needsConsent = false;
  Completer<void>? authenticationPending;
  final authorizationPrompts = <bool>[];

  @override
  Future<void> init(InitParameters params) async {
    initialization = params;
    initializeCalls++;
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    if (authenticationPending != null) await authenticationPending!.future;
    if (error != null) throw error!;
    return AuthenticationResults(
      user: const GoogleSignInUserData(
        email: 'person@example.com',
        id: 'google-user',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    authorizationPrompts.add(params.request.promptIfUnauthorized);
    expect(params.request.scopes, ['email']);
    if (needsConsent && !params.request.promptIfUnauthorized) return null;
    return const ClientAuthorizationTokenData(
      accessToken: 'google-access-token',
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async => signOutCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final google = FakeGooglePlatform();
  late GoogleSignInPlatform originalPlatform;
  late SupabaseClient client;
  late SupabaseAuthService service;
  late List<http.Request> requests;
  var rejectToken = false;

  setUpAll(() {
    originalPlatform = GoogleSignInPlatform.instance;
    GoogleSignInPlatform.instance = google;
  });
  tearDownAll(() => GoogleSignInPlatform.instance = originalPlatform);

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    requests = [];
    rejectToken = false;
    google
      ..idToken = 'google-id-token'
      ..error = null
      ..needsConsent = false
      ..authenticationPending = null
      ..authorizationPrompts.clear();
    client = SupabaseClient(
      'https://project.supabase.co',
      'public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/logout')) {
          return http.Response('{}', 200);
        }
        if (rejectToken) {
          return http.Response(
            '{"msg":"Token rejected","code":"invalid_credentials"}',
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'access_token': 'supabase-session-token',
            'refresh_token': 'supabase-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'test-user',
              'aud': 'authenticated',
              'app_metadata': {'provider': 'google'},
              'user_metadata': {},
              'created_at': '2026-10-30T00:00:00Z',
              'email': 'person@example.com',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    service = SupabaseAuthService(
      client,
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: 'ios.apps.googleusercontent.com',
      iosGoogleFactory: () => google,
    );
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await client.dispose();
  });

  test(
    'Exchanges native Google tokens for a confirmed Supabase session',
    () async {
      final signedIn = service.changes.firstWhere(
        (state) => state.event == AuthChangeEvent.signedIn,
      );
      await service.signInWithProvider(OAuthProvider.google);
      expect((await signedIn).session?.user.email, 'person@example.com');
      expect(service.session?.accessToken, 'supabase-session-token');
      expect(
        google.initialization?.serverClientId,
        'web.apps.googleusercontent.com',
      );
      expect(google.initialization?.clientId, isNull);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/auth/v1/token');
      expect(requests.single.url.queryParameters['grant_type'], 'id_token');
      expect(
        jsonDecode(requests.single.body),
        containsPair('provider', 'google'),
      );
      expect(
        jsonDecode(requests.single.body),
        containsPair('id_token', 'google-id-token'),
      );
      expect(
        jsonDecode(requests.single.body),
        containsPair('access_token', 'google-access-token'),
      );
      expect(google.authorizationPrompts, [false]);
    },
  );

  test('Requests consent when Google has no authorization token yet', () async {
    google.needsConsent = true;
    await service.signInWithProvider(OAuthProvider.google);
    expect(google.authorizationPrompts, [false, true]);
    expect(service.session, isNotNull);
  });

  test('Cancellation never exchanges tokens or creates a session', () async {
    google.error = const GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
    );
    await expectLater(
      service.signInWithProvider(OAuthProvider.google),
      throwsA(
        isA<AuthException>().having((e) => e.code, 'code', 'sign_in_canceled'),
      ),
    );
    expect(requests, isEmpty);
    expect(service.session, isNull);
  });

  test('Missing ID token never contacts Supabase', () async {
    google.idToken = null;
    await expectLater(
      service.signInWithProvider(OAuthProvider.google),
      throwsA(isA<AuthException>()),
    );
    expect(requests, isEmpty);
    expect(service.session, isNull);
  });

  test('Rejected token leaves no session and allows a fresh attempt', () async {
    rejectToken = true;
    await expectLater(
      service.signInWithProvider(OAuthProvider.google),
      throwsA(isA<AuthException>()),
    );
    expect(service.session, isNull);
    rejectToken = false;
    await service.signInWithProvider(OAuthProvider.google);
    expect(service.session, isNotNull);
    expect(google.initializeCalls, 1);
  });

  test('Configuration errors are distinct from user cancellation', () async {
    google.error = const GoogleSignInException(
      code: GoogleSignInExceptionCode.clientConfigurationError,
    );
    await expectLater(
      service.signInWithProvider(OAuthProvider.google),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          'google_not_configured',
        ),
      ),
    );
    expect(requests, isEmpty);
  });

  test('Missing web ID fails before invoking native Google', () async {
    final unconfigured = SupabaseAuthService(client, googleWebClientId: '');
    final signOutCalls = google.signOutCalls;
    await expectLater(
      unconfigured.signInWithProvider(OAuthProvider.google),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          'google_not_configured',
        ),
      ),
    );
    expect(google.signOutCalls, signOutCalls);
    expect(requests, isEmpty);
  });

  test('iOS requires its own client ID before opening Google', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final unconfigured = SupabaseAuthService(
      client,
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: '',
    );
    await expectLater(
      unconfigured.signInWithProvider(OAuthProvider.google),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          'google_not_configured',
        ),
      ),
    );
    expect(requests, isEmpty);
  });

  test(
    'iOS sends a fresh hashed nonce to Google and raw nonce to Supabase',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final nonces = <String>{};
      final previousInitializations = google.initializeCalls;
      for (var attempt = 0; attempt < 3; attempt++) {
        await service.signInWithProvider(OAuthProvider.google);
        final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
        final nonce = body['nonce'] as String;
        expect(base64Url.decode(nonce), hasLength(32));
        expect(nonces.add(nonce), isTrue);
        expect(
          google.initialization?.nonce,
          sha256.convert(utf8.encode(nonce)).toString(),
        );
        expect(
          google.initialization?.clientId,
          'ios.apps.googleusercontent.com',
        );
        expect(
          google.initialization?.serverClientId,
          'web.apps.googleusercontent.com',
        );
        expect(body['access_token'], 'google-access-token');
        expect(service.session, isNotNull);
        final signOutCalls = google.signOutCalls;
        await service.signOut();
        expect(google.signOutCalls, signOutCalls + 1);
        expect(service.session, isNull);
      }
      expect(google.initializeCalls, previousInitializations + 3);
    },
  );

  test(
    'iOS cancellation and rejected exchange discard their nonce on retry',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      google.error = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
      await expectLater(
        service.signInWithProvider(OAuthProvider.google),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'sign_in_canceled',
          ),
        ),
      );
      final canceledNonce = google.initialization!.nonce;
      expect(requests, isEmpty);
      google.error = null;
      rejectToken = true;
      await expectLater(
        service.signInWithProvider(OAuthProvider.google),
        throwsA(isA<AuthException>()),
      );
      final rejectedNonce = google.initialization!.nonce;
      expect(rejectedNonce, isNot(canceledNonce));
      expect(service.session, isNull);
      rejectToken = false;
      await service.signInWithProvider(OAuthProvider.google);
      expect(google.initialization!.nonce, isNot(rejectedNonce));
      expect(service.session, isNotNull);
    },
  );

  test('Concurrent iOS attempts cannot replace an in-flight nonce', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    google.authenticationPending = Completer<void>();
    final first = service.signInWithProvider(OAuthProvider.google);
    await Future<void>.delayed(Duration.zero);
    final nonce = google.initialization!.nonce;
    await expectLater(
      service.signInWithProvider(OAuthProvider.google),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          'sign_in_in_progress',
        ),
      ),
    );
    expect(google.initialization!.nonce, nonce);
    google.authenticationPending!.complete();
    await first;
    expect(service.session, isNotNull);
  });

  test(
    'Sign-out clears both the Supabase session and Google SDK account',
    () async {
      await service.signInWithProvider(OAuthProvider.google);
      final signOutCalls = google.signOutCalls;
      await service.signOut();
      expect(service.session, isNull);
      expect(google.signOutCalls, signOutCalls + 1);
      expect(requests.last.url.path, '/auth/v1/logout');
    },
  );
  const appleCredential = AuthorizationCredentialAppleID(
    userIdentifier: 'apple-user',
    givenName: null,
    familyName: null,
    authorizationCode: 'code',
    email: null,
    identityToken: 'apple-id-token',
    state: null,
  );

  test('Native Apple hashes a fresh nonce and sends the original nonce to Supabase', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final hashes = <String>[];
    final apple = SupabaseAuthService(
      client,
      appleCredentials: (hash) async {
        hashes.add(hash);
        return appleCredential;
      },
    );
    await apple.signInWithProvider(OAuthProvider.apple);
    await client.auth.signOut();
    await apple.signInWithProvider(OAuthProvider.apple);
    final tokens = requests
        .where((r) => r.url.path.endsWith('/token'))
        .toList();
    expect(tokens, hasLength(2));
    final nonces = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final body = jsonDecode(tokens[i].body) as Map;
      expect(body['provider'], 'apple');
      expect(body['id_token'], 'apple-id-token');
      final nonce = body['nonce'] as String;
      nonces.add(nonce);
      expect(sha256.convert(utf8.encode(nonce)).toString(), hashes[i]);
    }
    expect(nonces[0], isNot(nonces[1]));
    expect(apple.session, isNotNull);
  });

  test(
    'Canceling native Apple releases its lock and allows a new attempt',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var canceled = true;
      final apple = SupabaseAuthService(
        client,
        appleCredentials: (_) async {
          if (canceled) {
            throw const SignInWithAppleAuthorizationException(
              code: AuthorizationErrorCode.canceled,
              message: 'Canceled',
            );
          }
          return appleCredential;
        },
      );
      await expectLater(
        apple.signInWithProvider(OAuthProvider.apple),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'sign_in_canceled',
          ),
        ),
      );
      canceled = false;
      await apple.signInWithProvider(OAuthProvider.apple);
      expect(apple.session, isNotNull);
    },
  );
}
