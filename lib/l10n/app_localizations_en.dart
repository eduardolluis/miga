// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingIntro => 'Good food starts with a good plan.';

  @override
  String onboardingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get welcomeTitle => 'Your week, your way.';

  @override
  String get welcomeDescription => 'Plan your meals and organize your groceries with ease.';

  @override
  String get planTitle => 'Plan your week.';

  @override
  String get planDescription => 'Build a menu that fits your tastes and routine.';

  @override
  String get shoppingTitle => 'Organize your groceries.';

  @override
  String get shoppingDescription => 'Keep everything you need for your recipes in one list.';

  @override
  String get storesTitle => 'Explore nearby stores.';

  @override
  String get storesDescription => 'Find grocery stores near you.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get createAccount => 'Create account';

  @override
  String get login => 'Log in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get onboardingPlanIntro => 'A menu that fits your life.';

  @override
  String get onboardingShoppingIntro => 'Everything you need, in one list.';

  @override
  String get onboardingStoresIntro => 'Your next grocery stop, closer.';

  @override
  String get authTitle => 'Your table starts here.';

  @override
  String get authSubtitle => 'Sign in or create an account your way. No password.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get orWithEmail => 'or with email';

  @override
  String get emailMeCode => 'Email me a code';

  @override
  String get checkEmail => 'Check your email.';

  @override
  String codeSentTo(String email) {
    return 'Enter the code we sent to $email.';
  }

  @override
  String get emailCode => 'Verification code';

  @override
  String get verifyCode => 'Verify and continue';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get changeEmail => 'Use another email';

  @override
  String get codeRequired => 'Enter the complete code from your email.';

  @override
  String get invalidCode => 'The code is invalid or expired. Request a new one.';

  @override
  String get authError => 'We couldn’t complete sign-in. Check your connection and try again.';

  @override
  String get authRateLimited => 'Please wait a moment before requesting another code.';

  @override
  String get authUnavailable => 'Sign-in has not been configured yet.';

  @override
  String get authSuccess => 'You’re signed in to Miga.';

  @override
  String get signOut => 'Sign out';

  @override
  String get authBrowserError => 'We couldn’t open the browser to sign in. Check that Safari is available and try again.';

  @override
  String get appleSignInUnavailable => 'Sign in with Apple is not available yet.';
}
