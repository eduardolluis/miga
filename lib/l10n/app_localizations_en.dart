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
  String get welcomeDescription =>
      'Plan your meals and organize your groceries with ease.';

  @override
  String get planTitle => 'Plan your week.';

  @override
  String get planDescription =>
      'Build a menu that fits your tastes and routine.';

  @override
  String get shoppingTitle => 'Organize your groceries.';

  @override
  String get shoppingDescription =>
      'Keep everything you need for your recipes in one list.';

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
  String get authSubtitle =>
      'Sign in or create an account your way. No password.';

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
  String get invalidCode =>
      'The code is invalid or expired. Request a new one.';

  @override
  String get authError =>
      'We couldn’t complete sign-in. Check your connection and try again.';

  @override
  String get authRateLimited =>
      'Please wait a moment before requesting another code.';

  @override
  String get authUnavailable => 'Sign-in has not been configured yet.';

  @override
  String get authSuccess => 'You’re signed in to Miga.';

  @override
  String get signOut => 'Sign out';

  @override
  String get authBrowserError =>
      'We couldn’t open the browser to sign in. Check that Safari is available and try again.';

  @override
  String get appleSignInUnavailable =>
      'Sign in with Apple is not available yet.';

  @override
  String get homeGreeting => 'Make yourself at home.';

  @override
  String get homeTitle => 'What’s cooking today?';

  @override
  String homeMealsPlanned(int count) {
    return '$count of 21 meals planned';
  }

  @override
  String get homeWeek => 'Your week';

  @override
  String get homeToday => 'Today';

  @override
  String get homeDayPlan => 'On your table';

  @override
  String get homeBreakfast => 'Breakfast';

  @override
  String get homeLunch => 'Lunch';

  @override
  String get homeDinner => 'Dinner';

  @override
  String get homeEmptyMeal => 'Room for something good.';

  @override
  String get homeAddMeal => 'Add a meal';

  @override
  String get homeEditMeal => 'Edit meal';

  @override
  String get homeMealName => 'What will you eat?';

  @override
  String get homeMealHint => 'E.g. rice with vegetables';

  @override
  String get homeMealRequired => 'Enter a name for your meal.';

  @override
  String get homeSaveMeal => 'Save meal';

  @override
  String get homeRemoveMeal => 'Remove meal';

  @override
  String get homeStorageNotice => 'Your plan is saved on this device.';

  @override
  String get homeLoadError => 'We couldn’t load your plan.';

  @override
  String get homeSaveError => 'We couldn’t save your change. Please try again.';

  @override
  String get homeRetry => 'Try again';

  @override
  String get homeAccount => 'Your account';

  @override
  String get homeSignOutError => 'We couldn’t sign you out. Please try again.';

  @override
  String get homeInspiration => 'A little mealtime inspiration';

  @override
  String get homeRecipeTitle => 'Lemon & herb salmon';

  @override
  String get homeRecipeSubtitle => 'Simple ingredients. Plenty of color.';

  @override
  String get homeRecipeMeta => '30 min · 2 servings';

  @override
  String get homeViewRecipe => 'View recipe';

  @override
  String get homeIngredients => 'Ingredients';

  @override
  String get homeRecipeIngredients =>
      '2 salmon fillets\n300 g baby potatoes\n2 cups broccoli\n1 lemon\n1 tablespoon olive oil\nHerbs, salt and pepper to taste';

  @override
  String get homePreparation => 'Method';

  @override
  String get homeRecipeSteps =>
      '1. Preheat the oven to 200 °C. Cut the potatoes, toss with some of the oil and roast until starting to soften.\n\n2. Add the salmon and broccoli to the tray. Drizzle with the remaining oil, lemon and herbs.\n\n3. Bake until the fish is cooked through and the potatoes are tender. Serve with fresh lemon.';

  @override
  String get homeUseRecipe => 'Add to my plan';

  @override
  String get homeNavHome => 'Home';

  @override
  String get homeNavPlan => 'Plan';

  @override
  String get homeNavRecipes => 'Recipes';

  @override
  String get homeNavProfile => 'Profile';

  @override
  String get homeViewPlan => 'See plan';

  @override
  String get homeEmptyHeroTitle => 'Your next meal,\nyour way.';

  @override
  String get homeEmptyHeroDescription => 'No meal planned for this moment yet.';

  @override
  String get homeRecipeIdea => 'Get inspired';

  @override
  String get homeTodayPlan => 'YOUR DAILY PLAN';

  @override
  String get homeBudget => 'Weekly budget';

  @override
  String get homeBudgetEmptyTitle => 'Good food.\nA budget that fits.';

  @override
  String get homeBudgetEmptyDescription =>
      'Set an amount for this week and track your grocery spending.';

  @override
  String get homeSetBudget => 'Set a budget';

  @override
  String get homeEditBudget => 'Edit budget';

  @override
  String get homeBudgetLimit => 'Weekly spending limit';

  @override
  String get homeBudgetSpent => 'Recorded spending';

  @override
  String get homeCurrency => 'Currency';

  @override
  String get homeBudgetValidation =>
      'Enter valid amounts. The budget must be greater than zero.';

  @override
  String get homeBudgetOnTrack => 'Within your budget.';

  @override
  String get homeBudgetOver => 'You’re over your budget.';

  @override
  String get homeSave => 'Save changes';

  @override
  String get homeGroceryList => 'Grocery list';

  @override
  String get homeGroceryEmpty => 'Your list starts here.';

  @override
  String get homeGroceryDescription =>
      'Add products, enter prices and check items as you put them in your cart.';

  @override
  String get homeGroceryHint => 'E.g. tomatoes, 4';

  @override
  String get homeGroceryAdd => 'Add item';

  @override
  String get homeGroceryRemove => 'Remove item';

  @override
  String homeGroceryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items to pick up',
      one: '1 item to pick up',
    );
    return '$_temp0';
  }

  @override
  String get homeStores => 'Nearby stores';

  @override
  String get homeStoresSubtitle => 'Your next grocery stop';

  @override
  String get homeStoresEmpty => 'No stores to show yet.';

  @override
  String get homeStoresDescription =>
      'Get your list ready so you have everything at hand when you head out to shop.';

  @override
  String get homeProfileTitle => 'Your space in Miga';

  @override
  String get homeCalendarTitle => 'Your whole week.';

  @override
  String get homeCalendarSubtitle =>
      'Breakfast, lunch and dinner, one day at a time.';

  @override
  String get homePlannedDay => 'Has planned meals';

  @override
  String get homeEmptyDay => 'No planned meals';

  @override
  String get homeCarouselPlan => 'Show daily meal';

  @override
  String get homeCarouselBudget => 'Show weekly budget';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homeIdeasBreakfast => 'Breakfast ideas';

  @override
  String get homeIdeasLunch => 'Lunch ideas';

  @override
  String get homeIdeasDinner => 'Dinner ideas';

  @override
  String get homeIdeasNow => 'Swipe through recipes for this time of day.';

  @override
  String get homeIdeasManual =>
      'Swipe through recipes for your selected mealtime.';

  @override
  String get homeChangeMeal => 'Choose a mealtime';

  @override
  String get homeUseTime => 'Use the current time';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String get recipeSearch => 'Search recipes';

  @override
  String get recipeAll => 'All';

  @override
  String get recipeNoResults => 'No recipes match that name.';

  @override
  String get recipeAddIngredients => 'Add ingredients to my list';

  @override
  String get recipeIngredientsAdded => 'Ingredients added';

  @override
  String get homeOpenMaps => 'Open in maps';

  @override
  String get homeMapsUnavailable => 'We couldn’t open maps. Please try again.';

  @override
  String get homeGoodNight => 'Good night';

  @override
  String get recipeHaveIngredients => 'What do you have at home?';

  @override
  String get recipeIngredientsHint =>
      'Select ingredients. Recipes using at least one appear first, with the best matches at the top.';

  @override
  String get recipeClearIngredients => 'Clear';

  @override
  String recipeIngredientMatch(int have, int missing) {
    return '$have ingredients you have · $missing still needed';
  }

  @override
  String get proComingSoon => 'Coming soon';

  @override
  String get proOfferTitle => 'Less planning. More time for you.';

  @override
  String get proDiscover => 'Discover Miga Pro';

  @override
  String get proIntroduction =>
      'Your everyday essentials stay free. We’re building Pro to take more of the planning off your plate.';

  @override
  String get proFreePlan => 'Miga Free';

  @override
  String get proFreeDescription => 'Everything you can use today, at no cost.';

  @override
  String get proFreePlanning => 'Plan your meals and edit your weekly budget';

  @override
  String get proFreeRecipes =>
      'Browse recipes and filter by ingredients you have';

  @override
  String get proFreeShopping => 'Build and check off your grocery list';

  @override
  String get proInDevelopment => 'Coming soon · Features in development';

  @override
  String get proAutomaticPlans => 'A week planned for you';

  @override
  String get proAutomaticPlansDescription =>
      'Automatic weekly menus based on your preferences and household size.';

  @override
  String get proPantryPlans => 'Make the most of what you have';

  @override
  String get proPantryPlansDescription =>
      'Build an entire menu around your available ingredients, beyond the free recipe filters.';

  @override
  String get proSharedLists => 'A grocery list for your household';

  @override
  String get proSharedListsDescription =>
      'Share a list and keep everyone’s shopping updates in sync.';

  @override
  String get proLaunchNote =>
      'Pro subscriptions are not available yet. We’ll share pricing at launch. Your free tools remain available.';

  @override
  String get proKeepPlanning => 'Keep using Miga Free';

  @override
  String get carouselPrevious => 'Previous recipe';

  @override
  String get carouselNext => 'Next recipe';

  @override
  String carouselPosition(int current, int total) {
    return '$current of $total recipes';
  }

  @override
  String get groceryManualPrice =>
      'Prices entered by you, not verified store prices.';

  @override
  String get groceryUnitPrice => 'Price per item';

  @override
  String get groceryQuantity => 'Number of items';

  @override
  String get groceryPriceInvalid =>
      'Enter a price with up to 2 decimal places.';

  @override
  String get groceryQuantityInvalid => 'Enter a whole number from 1 to 999.';

  @override
  String get groceryRemovePrice => 'Remove price';

  @override
  String get groceryYourPrice => 'Your price';

  @override
  String get groceryAddPrice => 'Add price';

  @override
  String groceryEstimate(String amount) {
    return 'Shopping list estimate: $amount';
  }

  @override
  String get groceryPricesNeeded => 'Add prices to estimate your shop';

  @override
  String groceryPricesMissing(Object count) {
    return '$count products still need a price';
  }

  @override
  String groceryPriceCoverage(int count, String currency) {
    return '$count products have no price in $currency and are excluded from the estimate.';
  }

  @override
  String groceryCartProgress(int checked, int total) {
    return '$checked of $total items in your cart';
  }

  @override
  String get groceryReferences => 'Check Dominican price reports';

  @override
  String get groceryReferenceNote =>
      'Pro Consumidor reports are dated reference data. Check the product, package size and report date; they are not a live quote from your store.';

  @override
  String get groceryReferenceError =>
      'We couldn’t open the price reports. Please try again.';

  @override
  String get budgetPurpose =>
      'Recorded spending + this list’s entered prices. Cart checkmarks do not record spending.';

  @override
  String budgetShoppingOver(String amount) {
    return 'Known prices put you $amount over budget.';
  }

  @override
  String budgetAfterShopping(String amount) {
    return '$amount left after known shopping costs.';
  }

  @override
  String get budgetIncomplete =>
      'Add the missing prices before relying on this estimate.';

  @override
  String get groceryReferenceTitle => 'Official reference prices';

  @override
  String get groceryReferenceDisclaimer =>
      'Periodic observations by type of supermarket, not live store quotes. Check the package size and period before using an estimate.';

  @override
  String get groceryReferenceSearch => 'Search products in Spanish, e.g. arroz';

  @override
  String get groceryReferenceUnavailable =>
      'Reference prices are unavailable right now. You can still enter your own price.';

  @override
  String get groceryUseReference => 'Tap to use this dated estimate';

  @override
  String get groceryReferenceAttribution =>
      'Source: Pro Consumidor / Datos Abiertos · ODbL 1.0';

  @override
  String get groceryReferencePrice =>
      'Dated reference estimate, not a verified current store price.';

  @override
  String get groceryFindReference => 'Find an official reference price';

  @override
  String get groceryEstimateNote =>
      'Based on your prices and any dated references you chose. Actual checkout prices may differ.';

  @override
  String get storeCompare => 'Compare supermarket prices';

  @override
  String get storeSearch => 'Search prices';

  @override
  String get storeCompareNote =>
      'Online catalog prices by supermarket. Choose the exact brand and package size; different products are not a like-for-like comparison. Physical-store prices, offers and stock may differ.';

  @override
  String get storeNearby => 'See nearby stores';

  @override
  String get storeUnavailable =>
      'Live prices are unavailable for this store. You can still see its nearby locations.';

  @override
  String get storeSearchHelp =>
      'Search using at least 2 characters. Store catalogs use Spanish product names.';

  @override
  String get storeNoProducts => 'No matching products found in this catalog.';

  @override
  String storeObserved(String when) {
    return 'Consulted: $when';
  }

  @override
  String get storeUsePrice => 'Use this product and price';

  @override
  String get storeViewProduct => 'View product at the supermarket';

  @override
  String get storeOnlinePrice =>
      'Price consulted in the supermarket’s online catalog. Check the brand, package and date.';

  @override
  String get storeChooseItem => 'Which product do you want to compare?';

  @override
  String get storeRefreshPrice => 'Refresh price';
}
