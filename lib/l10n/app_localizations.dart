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

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home.'**
  String get homeGreeting;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'What’s cooking today?'**
  String get homeTitle;

  /// No description provided for @homeMealsPlanned.
  ///
  /// In en, this message translates to:
  /// **'{count} of 21 meals planned'**
  String homeMealsPlanned(int count);

  /// No description provided for @homeWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get homeWeek;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeDayPlan.
  ///
  /// In en, this message translates to:
  /// **'On your table'**
  String get homeDayPlan;

  /// No description provided for @homeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get homeBreakfast;

  /// No description provided for @homeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get homeLunch;

  /// No description provided for @homeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get homeDinner;

  /// No description provided for @homeEmptyMeal.
  ///
  /// In en, this message translates to:
  /// **'Room for something good.'**
  String get homeEmptyMeal;

  /// No description provided for @homeAddMeal.
  ///
  /// In en, this message translates to:
  /// **'Add a meal'**
  String get homeAddMeal;

  /// No description provided for @homeEditMeal.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get homeEditMeal;

  /// No description provided for @homeMealName.
  ///
  /// In en, this message translates to:
  /// **'What will you eat?'**
  String get homeMealName;

  /// No description provided for @homeMealHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. rice with vegetables'**
  String get homeMealHint;

  /// No description provided for @homeMealRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your meal.'**
  String get homeMealRequired;

  /// No description provided for @homeSaveMeal.
  ///
  /// In en, this message translates to:
  /// **'Save meal'**
  String get homeSaveMeal;

  /// No description provided for @homeRemoveMeal.
  ///
  /// In en, this message translates to:
  /// **'Remove meal'**
  String get homeRemoveMeal;

  /// No description provided for @homeStorageNotice.
  ///
  /// In en, this message translates to:
  /// **'Your plan is saved on this device.'**
  String get homeStorageNotice;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your plan.'**
  String get homeLoadError;

  /// No description provided for @homeSaveError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your change. Please try again.'**
  String get homeSaveError;

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get homeRetry;

  /// No description provided for @homeAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get homeAccount;

  /// No description provided for @homeSignOutError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t sign you out. Please try again.'**
  String get homeSignOutError;

  /// No description provided for @homeInspiration.
  ///
  /// In en, this message translates to:
  /// **'A little mealtime inspiration'**
  String get homeInspiration;

  /// No description provided for @homeRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lemon & herb salmon'**
  String get homeRecipeTitle;

  /// No description provided for @homeRecipeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple ingredients. Plenty of color.'**
  String get homeRecipeSubtitle;

  /// No description provided for @homeRecipeMeta.
  ///
  /// In en, this message translates to:
  /// **'30 min · 2 servings'**
  String get homeRecipeMeta;

  /// No description provided for @homeViewRecipe.
  ///
  /// In en, this message translates to:
  /// **'View recipe'**
  String get homeViewRecipe;

  /// No description provided for @homeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get homeIngredients;

  /// No description provided for @homeRecipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'2 salmon fillets\n300 g baby potatoes\n2 cups broccoli\n1 lemon\n1 tablespoon olive oil\nHerbs, salt and pepper to taste'**
  String get homeRecipeIngredients;

  /// No description provided for @homePreparation.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get homePreparation;

  /// No description provided for @homeRecipeSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Preheat the oven to 200 °C. Cut the potatoes, toss with some of the oil and roast until starting to soften.\n\n2. Add the salmon and broccoli to the tray. Drizzle with the remaining oil, lemon and herbs.\n\n3. Bake until the fish is cooked through and the potatoes are tender. Serve with fresh lemon.'**
  String get homeRecipeSteps;

  /// No description provided for @homeUseRecipe.
  ///
  /// In en, this message translates to:
  /// **'Add to my plan'**
  String get homeUseRecipe;

  /// No description provided for @homeNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavHome;

  /// No description provided for @homeNavPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get homeNavPlan;

  /// No description provided for @homeNavRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get homeNavRecipes;

  /// No description provided for @homeNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeNavProfile;

  /// No description provided for @homeViewPlan.
  ///
  /// In en, this message translates to:
  /// **'See plan'**
  String get homeViewPlan;

  /// No description provided for @homeEmptyHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next meal,\nyour way.'**
  String get homeEmptyHeroTitle;

  /// No description provided for @homeEmptyHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'No meal planned for this moment yet.'**
  String get homeEmptyHeroDescription;

  /// No description provided for @homeRecipeIdea.
  ///
  /// In en, this message translates to:
  /// **'Get inspired'**
  String get homeRecipeIdea;

  /// No description provided for @homeTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'YOUR DAILY PLAN'**
  String get homeTodayPlan;

  /// No description provided for @homeBudget.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget'**
  String get homeBudget;

  /// No description provided for @homeBudgetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Good food.\nA budget that fits.'**
  String get homeBudgetEmptyTitle;

  /// No description provided for @homeBudgetEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Set an amount for this week and track your grocery spending.'**
  String get homeBudgetEmptyDescription;

  /// No description provided for @homeSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set a budget'**
  String get homeSetBudget;

  /// No description provided for @homeEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get homeEditBudget;

  /// No description provided for @homeBudgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Weekly spending limit'**
  String get homeBudgetLimit;

  /// No description provided for @homeBudgetSpent.
  ///
  /// In en, this message translates to:
  /// **'Recorded spending'**
  String get homeBudgetSpent;

  /// No description provided for @homeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get homeCurrency;

  /// No description provided for @homeBudgetValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amounts. The budget must be greater than zero.'**
  String get homeBudgetValidation;

  /// No description provided for @homeBudgetOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Within your budget.'**
  String get homeBudgetOnTrack;

  /// No description provided for @homeBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'You’re over your budget.'**
  String get homeBudgetOver;

  /// No description provided for @homeSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get homeSave;

  /// No description provided for @homeGroceryList.
  ///
  /// In en, this message translates to:
  /// **'Grocery list'**
  String get homeGroceryList;

  /// No description provided for @homeGroceryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your list starts here.'**
  String get homeGroceryEmpty;

  /// No description provided for @homeGroceryDescription.
  ///
  /// In en, this message translates to:
  /// **'Add products, enter prices and check items as you put them in your cart.'**
  String get homeGroceryDescription;

  /// No description provided for @homeGroceryHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. tomatoes, 4'**
  String get homeGroceryHint;

  /// No description provided for @homeGroceryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get homeGroceryAdd;

  /// No description provided for @homeGroceryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get homeGroceryRemove;

  /// No description provided for @homeGroceryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item to pick up} other{{count} items to pick up}}'**
  String homeGroceryCount(int count);

  /// No description provided for @homeStores.
  ///
  /// In en, this message translates to:
  /// **'Nearby stores'**
  String get homeStores;

  /// No description provided for @homeStoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your next grocery stop'**
  String get homeStoresSubtitle;

  /// No description provided for @homeStoresEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stores to show yet.'**
  String get homeStoresEmpty;

  /// No description provided for @homeStoresDescription.
  ///
  /// In en, this message translates to:
  /// **'Get your list ready so you have everything at hand when you head out to shop.'**
  String get homeStoresDescription;

  /// No description provided for @homeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your space in Miga'**
  String get homeProfileTitle;

  /// No description provided for @homeCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your whole week.'**
  String get homeCalendarTitle;

  /// No description provided for @homeCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breakfast, lunch and dinner, one day at a time.'**
  String get homeCalendarSubtitle;

  /// No description provided for @homePlannedDay.
  ///
  /// In en, this message translates to:
  /// **'Has planned meals'**
  String get homePlannedDay;

  /// No description provided for @homeEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No planned meals'**
  String get homeEmptyDay;

  /// No description provided for @homeCarouselPlan.
  ///
  /// In en, this message translates to:
  /// **'Show daily meal'**
  String get homeCarouselPlan;

  /// No description provided for @homeCarouselBudget.
  ///
  /// In en, this message translates to:
  /// **'Show weekly budget'**
  String get homeCarouselBudget;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homeIdeasBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast ideas'**
  String get homeIdeasBreakfast;

  /// No description provided for @homeIdeasLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch ideas'**
  String get homeIdeasLunch;

  /// No description provided for @homeIdeasDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner ideas'**
  String get homeIdeasDinner;

  /// No description provided for @homeIdeasNow.
  ///
  /// In en, this message translates to:
  /// **'Swipe through recipes for this time of day.'**
  String get homeIdeasNow;

  /// No description provided for @homeIdeasManual.
  ///
  /// In en, this message translates to:
  /// **'Swipe through recipes for your selected mealtime.'**
  String get homeIdeasManual;

  /// No description provided for @homeChangeMeal.
  ///
  /// In en, this message translates to:
  /// **'Choose a mealtime'**
  String get homeChangeMeal;

  /// No description provided for @homeUseTime.
  ///
  /// In en, this message translates to:
  /// **'Use the current time'**
  String get homeUseTime;

  /// No description provided for @recipeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String recipeMinutes(int minutes);

  /// No description provided for @recipeServings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serving} other{{count} servings}}'**
  String recipeServings(int count);

  /// No description provided for @recipeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search recipes'**
  String get recipeSearch;

  /// No description provided for @recipeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get recipeAll;

  /// No description provided for @recipeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No recipes match that name.'**
  String get recipeNoResults;

  /// No description provided for @recipeAddIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients to my list'**
  String get recipeAddIngredients;

  /// No description provided for @recipeIngredientsAdded.
  ///
  /// In en, this message translates to:
  /// **'Ingredients added'**
  String get recipeIngredientsAdded;

  /// No description provided for @homeOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get homeOpenMaps;

  /// No description provided for @homeMapsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open maps. Please try again.'**
  String get homeMapsUnavailable;

  /// No description provided for @homeGoodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get homeGoodNight;

  /// No description provided for @recipeHaveIngredients.
  ///
  /// In en, this message translates to:
  /// **'What do you have at home?'**
  String get recipeHaveIngredients;

  /// No description provided for @recipeIngredientsHint.
  ///
  /// In en, this message translates to:
  /// **'Select ingredients. Recipes using at least one appear first, with the best matches at the top.'**
  String get recipeIngredientsHint;

  /// No description provided for @recipeClearIngredients.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get recipeClearIngredients;

  /// No description provided for @recipeIngredientMatch.
  ///
  /// In en, this message translates to:
  /// **'{have} ingredients you have · {missing} still needed'**
  String recipeIngredientMatch(int have, int missing);

  /// No description provided for @proComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get proComingSoon;

  /// No description provided for @proOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Less planning. More time for you.'**
  String get proOfferTitle;

  /// No description provided for @proDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover Miga Pro'**
  String get proDiscover;

  /// No description provided for @proIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Your everyday essentials stay free. We’re building Pro to take more of the planning off your plate.'**
  String get proIntroduction;

  /// No description provided for @proFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Miga Free'**
  String get proFreePlan;

  /// No description provided for @proFreeDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything you can use today, at no cost.'**
  String get proFreeDescription;

  /// No description provided for @proFreePlanning.
  ///
  /// In en, this message translates to:
  /// **'Plan your meals and edit your weekly budget'**
  String get proFreePlanning;

  /// No description provided for @proFreeRecipes.
  ///
  /// In en, this message translates to:
  /// **'Browse recipes and filter by ingredients you have'**
  String get proFreeRecipes;

  /// No description provided for @proFreeShopping.
  ///
  /// In en, this message translates to:
  /// **'Build and check off your grocery list'**
  String get proFreeShopping;

  /// No description provided for @proInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Coming soon · Features in development'**
  String get proInDevelopment;

  /// No description provided for @proAutomaticPlans.
  ///
  /// In en, this message translates to:
  /// **'A week planned for you'**
  String get proAutomaticPlans;

  /// No description provided for @proAutomaticPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatic weekly menus based on your preferences and household size.'**
  String get proAutomaticPlansDescription;

  /// No description provided for @proPantryPlans.
  ///
  /// In en, this message translates to:
  /// **'Make the most of what you have'**
  String get proPantryPlans;

  /// No description provided for @proPantryPlansDescription.
  ///
  /// In en, this message translates to:
  /// **'Build an entire menu around your available ingredients, beyond the free recipe filters.'**
  String get proPantryPlansDescription;

  /// No description provided for @proSharedLists.
  ///
  /// In en, this message translates to:
  /// **'A grocery list for your household'**
  String get proSharedLists;

  /// No description provided for @proSharedListsDescription.
  ///
  /// In en, this message translates to:
  /// **'Share a list and keep everyone’s shopping updates in sync.'**
  String get proSharedListsDescription;

  /// No description provided for @proLaunchNote.
  ///
  /// In en, this message translates to:
  /// **'Pro subscriptions are not available yet. We’ll share pricing at launch. Your free tools remain available.'**
  String get proLaunchNote;

  /// No description provided for @proKeepPlanning.
  ///
  /// In en, this message translates to:
  /// **'Keep using Miga Free'**
  String get proKeepPlanning;

  /// No description provided for @carouselPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous recipe'**
  String get carouselPrevious;

  /// No description provided for @carouselNext.
  ///
  /// In en, this message translates to:
  /// **'Next recipe'**
  String get carouselNext;

  /// No description provided for @carouselPosition.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total} recipes'**
  String carouselPosition(int current, int total);

  /// No description provided for @groceryManualPrice.
  ///
  /// In en, this message translates to:
  /// **'Prices entered by you, not verified store prices.'**
  String get groceryManualPrice;

  /// No description provided for @groceryUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per item'**
  String get groceryUnitPrice;

  /// No description provided for @groceryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Number of items'**
  String get groceryQuantity;

  /// No description provided for @groceryPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a price with up to 2 decimal places.'**
  String get groceryPriceInvalid;

  /// No description provided for @groceryQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 999.'**
  String get groceryQuantityInvalid;

  /// No description provided for @groceryRemovePrice.
  ///
  /// In en, this message translates to:
  /// **'Remove price'**
  String get groceryRemovePrice;

  /// No description provided for @groceryYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Your price'**
  String get groceryYourPrice;

  /// No description provided for @groceryAddPrice.
  ///
  /// In en, this message translates to:
  /// **'Add price'**
  String get groceryAddPrice;

  /// No description provided for @groceryEstimate.
  ///
  /// In en, this message translates to:
  /// **'Shopping list estimate: {amount}'**
  String groceryEstimate(String amount);

  /// No description provided for @groceryPricesNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add prices to estimate your shop'**
  String get groceryPricesNeeded;

  /// No description provided for @groceryPricesMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} products still need a price'**
  String groceryPricesMissing(Object count);

  /// No description provided for @groceryPriceCoverage.
  ///
  /// In en, this message translates to:
  /// **'{count} products have no price in {currency} and are excluded from the estimate.'**
  String groceryPriceCoverage(int count, String currency);

  /// No description provided for @groceryCartProgress.
  ///
  /// In en, this message translates to:
  /// **'{checked} of {total} items in your cart'**
  String groceryCartProgress(int checked, int total);

  /// No description provided for @groceryReferences.
  ///
  /// In en, this message translates to:
  /// **'Check Dominican price reports'**
  String get groceryReferences;

  /// No description provided for @groceryReferenceNote.
  ///
  /// In en, this message translates to:
  /// **'Pro Consumidor reports are dated reference data. Check the product, package size and report date; they are not a live quote from your store.'**
  String get groceryReferenceNote;

  /// No description provided for @groceryReferenceError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open the price reports. Please try again.'**
  String get groceryReferenceError;

  /// No description provided for @budgetPurpose.
  ///
  /// In en, this message translates to:
  /// **'Recorded spending + this list’s entered prices. Cart checkmarks do not record spending.'**
  String get budgetPurpose;

  /// No description provided for @budgetShoppingOver.
  ///
  /// In en, this message translates to:
  /// **'Known prices put you {amount} over budget.'**
  String budgetShoppingOver(String amount);

  /// No description provided for @budgetAfterShopping.
  ///
  /// In en, this message translates to:
  /// **'{amount} left after known shopping costs.'**
  String budgetAfterShopping(String amount);

  /// No description provided for @budgetIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Add the missing prices before relying on this estimate.'**
  String get budgetIncomplete;

  /// No description provided for @groceryReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Official reference prices'**
  String get groceryReferenceTitle;

  /// No description provided for @groceryReferenceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Periodic observations by type of supermarket, not live store quotes. Check the package size and period before using an estimate.'**
  String get groceryReferenceDisclaimer;

  /// No description provided for @groceryReferenceSearch.
  ///
  /// In en, this message translates to:
  /// **'Search products in Spanish, e.g. arroz'**
  String get groceryReferenceSearch;

  /// No description provided for @groceryReferenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reference prices are unavailable right now. You can still enter your own price.'**
  String get groceryReferenceUnavailable;

  /// No description provided for @groceryUseReference.
  ///
  /// In en, this message translates to:
  /// **'Tap to use this dated estimate'**
  String get groceryUseReference;

  /// No description provided for @groceryReferenceAttribution.
  ///
  /// In en, this message translates to:
  /// **'Source: Pro Consumidor / Datos Abiertos · ODbL 1.0'**
  String get groceryReferenceAttribution;

  /// No description provided for @groceryReferencePrice.
  ///
  /// In en, this message translates to:
  /// **'Dated reference estimate, not a verified current store price.'**
  String get groceryReferencePrice;

  /// No description provided for @groceryFindReference.
  ///
  /// In en, this message translates to:
  /// **'Find an official reference price'**
  String get groceryFindReference;

  /// No description provided for @groceryEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Based on your prices and any dated references you chose. Actual checkout prices may differ.'**
  String get groceryEstimateNote;

  /// No description provided for @storeCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare supermarket prices'**
  String get storeCompare;

  /// No description provided for @storeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search prices'**
  String get storeSearch;

  /// No description provided for @storePriceSmartNote.
  ///
  /// In en, this message translates to:
  /// **'PriceSmart: Los Prados club (6801), membership required. Pack prices; other clubs may differ.'**
  String get storePriceSmartNote;

  /// No description provided for @storeCompareNote.
  ///
  /// In en, this message translates to:
  /// **'Online catalog prices by supermarket. Choose the exact brand and package size; different products are not a like-for-like comparison. Physical-store prices, offers and stock may differ.'**
  String get storeCompareNote;

  /// No description provided for @storeNearby.
  ///
  /// In en, this message translates to:
  /// **'See nearby stores'**
  String get storeNearby;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live prices are unavailable for this store. You can still see its nearby locations.'**
  String get storeUnavailable;

  /// No description provided for @storeSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'Search using at least 2 characters. Store catalogs use Spanish product names.'**
  String get storeSearchHelp;

  /// No description provided for @storeNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No matching products found in this catalog.'**
  String get storeNoProducts;

  /// No description provided for @storeObserved.
  ///
  /// In en, this message translates to:
  /// **'Consulted: {when}'**
  String storeObserved(String when);

  /// No description provided for @storeUsePrice.
  ///
  /// In en, this message translates to:
  /// **'Use this product and price'**
  String get storeUsePrice;

  /// No description provided for @storeViewProduct.
  ///
  /// In en, this message translates to:
  /// **'View product at the supermarket'**
  String get storeViewProduct;

  /// No description provided for @storeOnlinePrice.
  ///
  /// In en, this message translates to:
  /// **'Price consulted in the supermarket’s online catalog. Check the brand, package and date.'**
  String get storeOnlinePrice;

  /// No description provided for @storeChooseItem.
  ///
  /// In en, this message translates to:
  /// **'Which product do you want to compare?'**
  String get storeChooseItem;

  /// No description provided for @storeRefreshPrice.
  ///
  /// In en, this message translates to:
  /// **'Refresh price'**
  String get storeRefreshPrice;

  /// No description provided for @groceryEstimating.
  ///
  /// In en, this message translates to:
  /// **'Estimating…'**
  String get groceryEstimating;

  /// No description provided for @groceryEstimateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Estimate unavailable'**
  String get groceryEstimateUnavailable;

  /// No description provided for @groceryAutoEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated purchase: one package per quantity. Review size and brand.'**
  String get groceryAutoEstimate;

  /// No description provided for @groceryItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully'**
  String get groceryItemAdded;

  /// No description provided for @budgetRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Meals for your budget'**
  String get budgetRecipeTitle;

  /// No description provided for @budgetRecipeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Recipe prices are available in Dominican pesos. Set your budget to DOP to compare.'**
  String get budgetRecipeCurrency;

  /// No description provided for @budgetMealAllowance.
  ///
  /// In en, this message translates to:
  /// **'Target per meal: {amount}. Remaining budget divided across the meal slots left this week.'**
  String budgetMealAllowance(Object amount);

  /// No description provided for @budgetCostNote.
  ///
  /// In en, this message translates to:
  /// **'Estimated ingredients consumed, not full shopping packages. Kitchen quantities and produce weights are approximate. Prices may combine stores; buying all packages can cost more.'**
  String get budgetCostNote;

  /// No description provided for @budgetNoConfirmedFit.
  ///
  /// In en, this message translates to:
  /// **'No fully priced meal fits this target yet. Review costs or adjust your budget.'**
  String get budgetNoConfirmedFit;

  /// No description provided for @budgetRecipeTotal.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount} for {servings} servings'**
  String budgetRecipeTotal(Object amount, Object servings);

  /// No description provided for @budgetRecipePartial.
  ///
  /// In en, this message translates to:
  /// **'Missing prices or package sizes: {count} ingredients.'**
  String budgetRecipePartial(Object count);

  /// No description provided for @budgetRecipeFits.
  ///
  /// In en, this message translates to:
  /// **'Within your meal target'**
  String get budgetRecipeFits;

  /// No description provided for @budgetRecipeOver.
  ///
  /// In en, this message translates to:
  /// **'Above your meal target'**
  String get budgetRecipeOver;

  /// No description provided for @budgetCostDetails.
  ///
  /// In en, this message translates to:
  /// **'Ingredient costs'**
  String get budgetCostDetails;

  /// No description provided for @budgetPieces.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get budgetPieces;

  /// No description provided for @budgetMealTarget.
  ///
  /// In en, this message translates to:
  /// **'Target per meal'**
  String get budgetMealTarget;

  /// No description provided for @budgetTargetNote.
  ///
  /// In en, this message translates to:
  /// **'Based on your remaining budget and the meals left this week.'**
  String get budgetTargetNote;

  /// No description provided for @budgetKnownSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal of priced ingredients · incomplete'**
  String get budgetKnownSubtotal;

  /// No description provided for @budgetPriceCoverage.
  ///
  /// In en, this message translates to:
  /// **'{priced} of {total} ingredients priced'**
  String budgetPriceCoverage(Object priced, Object total);

  /// No description provided for @budgetEstimateInfo.
  ///
  /// In en, this message translates to:
  /// **'How this estimate works'**
  String get budgetEstimateInfo;

  /// No description provided for @budgetPackPrice.
  ///
  /// In en, this message translates to:
  /// **'Reference package: {amount}'**
  String budgetPackPrice(Object amount);

  /// No description provided for @budgetRecipeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated recipe total'**
  String get budgetRecipeEstimate;
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
