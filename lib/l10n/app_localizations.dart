import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @onboardingIntro.
  ///
  /// In en, this message translates to:
  /// **'Good food starts with a good plan.'**
  String get onboardingIntro;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week, your way.'**
  String get welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan your meals and organize your groceries with ease.'**
  String get welcomeDescription;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your week.'**
  String get planTitle;

  /// No description provided for @planDescription.
  ///
  /// In en, this message translates to:
  /// **'Build a menu that fits your tastes and routine.'**
  String get planDescription;

  /// No description provided for @shoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your groceries.'**
  String get shoppingTitle;

  /// No description provided for @shoppingDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep everything you need for your recipes in one list.'**
  String get shoppingDescription;

  /// No description provided for @storesTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore nearby stores.'**
  String get storesTitle;

  /// No description provided for @storesDescription.
  ///
  /// In en, this message translates to:
  /// **'Find grocery stores near you.'**
  String get storesDescription;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @onboardingPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'A menu that fits your life.'**
  String get onboardingPlanIntro;

  /// No description provided for @onboardingShoppingIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything you need, in one list.'**
  String get onboardingShoppingIntro;

  /// No description provided for @onboardingStoresIntro.
  ///
  /// In en, this message translates to:
  /// **'Your next grocery stop, closer.'**
  String get onboardingStoresIntro;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Your table starts here.'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account your way. No password.'**
  String get authSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or with email'**
  String get orWithEmail;

  /// No description provided for @emailMeCode.
  ///
  /// In en, this message translates to:
  /// **'Email me a code'**
  String get emailMeCode;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email.'**
  String get checkEmail;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {email}.'**
  String codeSentTo(String email);

  /// No description provided for @emailCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get emailCode;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use another email'**
  String get changeEmail;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the complete code from your email.'**
  String get codeRequired;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is invalid or expired. Request a new one.'**
  String get invalidCode;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t complete sign-in. Check your connection and try again.'**
  String get authError;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before requesting another code.'**
  String get authRateLimited;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in has not been configured yet.'**
  String get authUnavailable;

  /// No description provided for @authSuccess.
  ///
  /// In en, this message translates to:
  /// **'You’re signed in to Miga.'**
  String get authSuccess;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @authBrowserError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open the browser to sign in. Check that Safari is available and try again.'**
  String get authBrowserError;

  /// No description provided for @appleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple is not available yet.'**
  String get appleSignInUnavailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
