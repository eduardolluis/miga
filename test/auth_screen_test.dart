import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miga/app.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/screens/auth/auth_screen.dart';
import 'package:miga/screens/onboarding/onboarding_screen.dart';
import 'package:miga/services/auth_service.dart';
import 'package:miga/widgets/verification_code_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

Widget authApp(
  FakeAuthService service, {
  Locale locale = const Locale('es'),
  bool disableAnimations = false,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: disableAnimations
        ? (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          )
        : null,
    home: AuthScreen(authService: service),
  );
}

Future<void> requestCode(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), ' person@example.com ');
  await tester.tap(find.text('Enviarme un código'));
  await tester.pumpAndSettle();
}

void main() {
  late FakeAuthService service;
  setUp(() => service = FakeAuthService());
  tearDown(() async => service.events.close());

  testWidgets('Validates email before sending and never asks for a password', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Contraseña'), findsNothing);
    await tester.tap(find.text('Enviarme un código'));
    await tester.pumpAndSettle();
    expect(find.text('Introduce tu correo'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.tap(find.text('Enviarme un código'));
    await tester.pumpAndSettle();
    expect(find.text('Introduce un correo válido'), findsOneWidget);
    expect(service.sentEmail, isNull);
  });

  testWidgets('Login and code screens do not bounce when swiped on iOS', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await tester.pumpAndSettle();

    Future<void> expectNoBounce() async {
      final scrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      final state = tester.state<ScrollableState>(scrollable);
      expect(state.position.maxScrollExtent, 0);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CustomScrollView)),
      );
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      expect(state.position.pixels, 0);
      await gesture.moveBy(const Offset(0, -200));
      await tester.pump();
      expect(state.position.pixels, 0);
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await expectNoBounce();
    await requestCode(tester);
    await expectNoBounce();
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('Sends trimmed email, verifies code, then signs out', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await requestCode(tester);
    expect(service.sentEmail, 'person@example.com');
    expect(service.sentLanguage, 'es');
    expect(find.text('Revisa tu correo.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verificar y continuar'));
    await tester.pumpAndSettle();
    expect(service.verifiedEmail, 'person@example.com');
    expect(service.verifiedCode, '123456');
    expect(find.text('Ya estás en Miga.'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Enviarme un código'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Code input survives reload while focused and after validation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await requestCode(tester);
    await tester.tap(find.text('–').first);
    await tester.enterText(find.byType(TextFormField), '123');
    final reload = tester.binding.reassembleApplication();
    await tester.pump();
    await reload;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '123',
    );
    await tester.tap(find.text('Verificar y continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final errorReload = tester.binding.reassembleApplication();
    await tester.pump();
    await errorReload;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Usar otro correo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(VerificationCodeField), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('Tapping code boxes opens input and displays typed digits', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await requestCode(tester);
    await tester.tap(find.text('Verificar y continuar'));
    await tester.pumpAndSettle();
    final error = tester.widget<Text>(
      find.text('Introduce el código completo de tu correo.'),
    );
    expect(error.style?.color, const Color(0xFFFF6B6B));
    expect(error.style?.fontWeight, FontWeight.w600);
    expect(error.style?.backgroundColor, isNull);
    expect(
      tester
          .widget<VerificationCodeField>(find.byType(VerificationCodeField))
          .hasError,
      isTrue,
    );
    await tester.tap(find.text('–').first);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    tester.testTextInput.enterText('1');
    await tester.pump();
    expect(
      tester
          .widget<VerificationCodeField>(find.byType(VerificationCodeField))
          .hasError,
      isFalse,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is Text && widget.data == '1'),
      findsOneWidget,
    );
    tester.testTextInput.enterText('123456');
    await tester.pump();
    expect(find.text('–'), findsNothing);
    expect(service.verifiedCode, isNull);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(service.verifiedCode, '123456');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('First code box pastes a complete code from the clipboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service, locale: const Locale('en')));
    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text('Email me a code'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': '12 34 56 78'} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.longPress(find.text('–').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(service.verifiedCode, '123456');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Code boxes stay fixed at six and discard excess digits', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await requestCode(tester);
    expect(find.byType(VerificationCodeField), findsOneWidget);
    expect(find.text('–'), findsNWidgets(6));
    final boxes = find.descendant(
      of: find.byType(VerificationCodeField),
      matching: find.byType(AnimatedContainer),
    );
    final sizes = List.generate(
      6,
      (index) => tester.getSize(
        find
            .descendant(
              of: boxes.at(index),
              matching: find.byType(DecoratedBox),
            )
            .first,
      ),
    );
    for (final size in sizes) {
      expect(size.width, closeTo(sizes.first.width, 0.01));
      expect(size.height, sizes.first.height);
    }
    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.verifiedCode, isNull);
    expect(find.text('–'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '12 34 56 78');
    await tester.pump();
    expect(find.text('–'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '123456',
    );
    expect(
      find.descendant(
        of: find.byType(VerificationCodeField),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(6),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(service.verifiedCode, '123456');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Failed delivery stays on email form and can be retried', (
    tester,
  ) async {
    service.sendError = const AuthException('offline');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await requestCode(tester);
    expect(find.text('Revisa tu correo.'), findsNothing);
    expect(find.textContaining('No pudimos'), findsOneWidget);
    service.sendError = null;
    await tester.tap(find.text('Enviarme un código'));
    await tester.pumpAndSettle();
    expect(find.text('Revisa tu correo.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Expired code highlights boxes, shakes, and unlocks resend immediately',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(authApp(service));
      await requestCode(tester);
      await tester.tap(find.text('Verificar y continuar'));
      await tester.pumpAndSettle();
      expect(service.verifiedCode, isNull);
      service.verifyError = const AuthException('expired', code: 'otp_expired');
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pump();
      final boxes = find.descendant(
        of: find.byType(VerificationCodeField),
        matching: find.byType(AnimatedContainer),
      );
      final initialX = tester.getCenter(boxes.first).dx;
      await tester.tap(find.text('Verificar y continuar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.getCenter(boxes.first).dx, isNot(closeTo(initialX, 0.01)));
      await tester.pumpAndSettle();
      expect(tester.getCenter(boxes.first).dx, closeTo(initialX, 0.01));
      expect(find.textContaining('El código no es válido'), findsOneWidget);
      expect(service.session, isNull);
      expect(
        tester
            .widget<VerificationCodeField>(find.byType(VerificationCodeField))
            .hasError,
        isTrue,
      );
      for (final box in tester.widgetList<AnimatedContainer>(boxes)) {
        final decoration = box.decoration! as BoxDecoration;
        expect(
          (decoration.border! as Border).top.color,
          const Color(0xFFFF6B6B),
        );
      }
      final resend = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Reenviar código'),
      );
      expect(resend.onPressed, isNotNull);
      await tester.tap(find.text('Reenviar código'));
      await tester.pumpAndSettle();
      expect(find.textContaining('El código no es válido'), findsNothing);
      expect(
        tester
            .widget<VerificationCodeField>(find.byType(VerificationCodeField))
            .hasError,
        isFalse,
      );
      expect(find.textContaining('Reenviar en '), findsOneWidget);
      await tester.tap(find.text('Usar otro correo'));
      await tester.pumpAndSettle();
      expect(find.text('Enviarme un código'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Resend countdown is muted without underline until it becomes actionable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(authApp(service));
      await requestCode(tester);
      final countdown = find.textContaining('Reenviar en ');
      final disabledResend = tester.widget<TextButton>(
        find.ancestor(of: countdown, matching: find.byType(TextButton)),
      );
      final disabledStyle = DefaultTextStyle.of(tester.element(countdown)).style
          .merge(tester.widget<Text>(countdown).style);
      expect(disabledResend.onPressed, isNull);
      expect(disabledStyle.decoration, anyOf(isNull, TextDecoration.none));
      expect(disabledStyle.color!.a, lessThan(1));

      service.verifyError = const AuthException('offline');
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verificar y continuar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(service.verifyCalls, 1);
      expect(find.textContaining('Reenviar en '), findsOneWidget);
      expect(
        tester
            .widget<VerificationCodeField>(find.byType(VerificationCodeField))
            .hasError,
        isFalse,
      );

      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      final active = find.text('Reenviar código');
      final activeResend = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Reenviar código'),
      );
      final activeStyle = DefaultTextStyle.of(tester.element(active)).style
          .merge(tester.widget<Text>(active).style);
      expect(activeResend.onPressed, isNotNull);
      expect(activeStyle.decoration, TextDecoration.underline);
      expect(activeStyle.color, Colors.white);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Reduced motion keeps invalid code boxes still and highlighted', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    service.verifyError = const AuthException('expired', code: 'otp_expired');
    await tester.pumpWidget(authApp(service, disableAnimations: true));
    await requestCode(tester);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pump();
    final boxes = find.descendant(
      of: find.byType(VerificationCodeField),
      matching: find.byType(AnimatedContainer),
    );
    final initialX = tester.getCenter(boxes.first).dx;
    await tester.tap(find.text('Verificar y continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(tester.getCenter(boxes.first).dx, initialX);
    await tester.pumpAndSettle();
    for (final box in tester.widgetList<AnimatedContainer>(boxes)) {
      final decoration = box.decoration! as BoxDecoration;
      expect((decoration.border! as Border).top.color, const Color(0xFFFF6B6B));
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Email request disables controls until it finishes', (
    tester,
  ) async {
    service.sendPending = Completer<void>();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(authApp(service));
    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text('Enviarme un código'));
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enviarme un código'),
    );
    expect(button.onPressed, isNull);
    service.sendPending!.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('Provider buttons on $platform wait for actual session', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(authApp(service));
      expect(
        find.text('Continuar con Apple'),
        platform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();
      expect(service.provider, OAuthProvider.google);
      expect(find.text('Ya estás en Miga.'), findsNothing);
      if (platform == TargetPlatform.iOS) {
        await tester.tap(find.text('Continuar con Apple'));
        await tester.pumpAndSettle();
        expect(service.provider, OAuthProvider.google);
        expect(
          find.text(
            'El inicio de sesión con Apple todavía no está disponible.',
          ),
          findsOneWidget,
        );
      }
      await service.verifyCode('person@example.com', '123456');
      await tester.pumpAndSettle();
      expect(find.text('Ya estás en Miga.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, variant: TargetPlatformVariant({platform}));
  }

  testWidgets('Canceling Google releases controls without an error', (
    tester,
  ) async {
    service.providerPending = Completer<void>();
    service.providerError = const AuthException(
      'Canceled',
      code: 'sign_in_canceled',
    );
    await tester.pumpWidget(authApp(service));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Continuar con Google'),
          )
          .onPressed,
      isNull,
    );
    service.providerPending!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos'), findsNothing);
    expect(find.text('Ya estás en Miga.'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Continuar con Google'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Missing Google configuration shows the setup message', (
    tester,
  ) async {
    service.providerError = const AuthException(
      'Missing client ID',
      code: 'google_not_configured',
    );
    await tester.pumpWidget(authApp(service));
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.text('El acceso todavía no está configurado.'), findsOneWidget);
    expect(find.text('Ya estás en Miga.'), findsNothing);
  });

  testWidgets('Apple shows an English notification without starting OAuth', (
    tester,
  ) async {
    await tester.pumpWidget(authApp(service, locale: const Locale('en')));
    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Sign in with Apple is not available yet.'),
      ),
      findsOneWidget,
    );
    expect(service.provider, isNull);
    expect(
      find.text(
        'We couldn’t complete sign-in. Check your connection and try again.',
      ),
      findsNothing,
    );
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets(
    'Restores session at startup and returns to onboarding on signout',
    (tester) async {
      await service.verifyCode('person@example.com', '123456');
      await tester.pumpWidget(MigaApp(authService: service));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      await service.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets('English code screen fits small display with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: AuthScreen(authService: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      150,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.ensureVisible(find.text('Email me a code'));
    await tester.tap(find.text('Email me a code'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Check your email.'),
      -150,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Check your email.'), findsOneWidget);
    expect(service.sentLanguage, 'en');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
