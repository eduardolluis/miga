# Miga Architecture

Miga is a Flutter application for Android and iOS. Supabase handles authentication and optional account-scoped cloud sync. A durable local copy supports offline use; cloud writes use compare-and-swap revisions and the server isolates accounts with RLS. Nine bilingual recipes and their images are bundled with the app.

## Project layout

```text
lib/
├── main.dart
├── app/
│   ├── miga_app.dart
│   └── navigation/
│       ├── app_shell.dart
│       ├── app_tab.dart
│       └── widgets/
├── core/
│   └── theme/
├── features/
│   ├── auth/          # data, domain, presentation
│   ├── budget/        # domain, presentation
│   ├── groceries/     # domain, presentation
│   ├── home/          # application, data, domain, presentation
│   ├── meal_plan/     # data, domain, presentation
│   ├── onboarding/    # presentation
│   ├── profile/       # presentation
│   ├── recipes/       # data, domain, presentation
│   └── stores/        # data
└── l10n/

test/
├── app/navigation/
├── features/
│   ├── auth/
│   ├── home/
│   ├── meal_plan/
│   └── onboarding/
└── support/
```

Only layers with an actual responsibility are present. A feature with a single screen does not need empty application, data, and domain folders.

- **`app/`** starts and composes the application. `MigaApp` selects onboarding or the authenticated `AppShell`. The shell creates account-scoped stores, owns tab navigation, and coordinates actions that open editors in other features.
- **`core/`** contains shared visual foundations: application themes and colors. Feature-specific widgets stay in their own feature.
- **`domain/`** contains feature models and storage contracts. `WeeklyBudget`, `GroceryItem`, and `MealSlot` live with their respective functionality. `HomeDetails` aggregates budget and grocery data without owning those models. Authentication retains Supabase types in its existing contract to preserve provider behavior.
- **`data/`** implements contracts using Supabase or local preferences. Controllers depend on contracts, not these concrete implementations.
- **`application/`** coordinates state and operations. `HomeController` publishes changes after successful writes and keeps failed loads visible for retry.
- **`presentation/`** contains screens/pages, widgets, sheets, and view-only models or styles. Icons and translated labels for `MealSlot` are provided by a presentation extension, not the stored enum.
- **`l10n/`** keeps the ARB catalogs and Flutter-generated localization files together. Edit the ARB files and run `flutter gen-l10n`; do not edit generated Dart files manually.

`HomeScreen` is the daily summary. `MealPlanPage` is the complete weekly calendar. The calendar receives values and callbacks rather than depending on the home controller, so the two features do not form a dependency cycle. Recipe cards and recipe details are separate widgets, and the onboarding background and page indicator are also separate from their screen.

## Dependency conventions

Use `package:miga/...` imports for application code so moving a file does not require counting parent directories. Prefer direct imports over barrel files that hide dependencies.

`app` may compose features. Features may use another feature's public models or focused widgets when required; keep dependencies acyclic. Domain and application code must not import presentation or concrete data implementations. Shared code belongs in `core` only when it is actually shared.

Tests follow the path of the production feature or application component they verify. Reusable test doubles belong in `test/support`; tests must not import another test file to obtain a fake.

Comments explain constraints and decisions that are not evident from names: provider session confirmation, Google nonce handling, storage compatibility, and carousel height measurement. Avoid comments that repeat the next statement.

## Persistence compatibility

`LocalMealPlanStore` implements `MealPlanStore`. `LocalHomeDetailsStore` implements `HomeDetailsStore`. Both use `shared_preferences`, and their existing schema is unchanged:

- Meals use `miga.meals.v1.<userId>` with `YYYY-MM-DD:slot` keys.
- Budgets and groceries use `miga.home.v1.<userId>` with the JSON fields `budgets` and `groceries`.
- Budget weeks use the Monday date in the existing, unpadded format (`2026-2-2`). This differs deliberately from padded meal dates.
- Enum names, JSON fields, and versioned preference keys must not change as part of a file move. A future schema change needs an explicit migration.

The storage and controller tests cover account isolation, reloads, failures, and reading data saved before the reorganization. Authentication tests continue to cover OTP, native Google flows, nonces, cancellation, and navigation.

## Validation

```sh
flutter analyze --no-pub
flutter test --no-pub
```

Home suggestions come from `RecipeCatalog`, filtered by the local clock. The controller preserves an explicit mealtime override, and the app refreshes time every minute and when resumed. Recipe ingredients can be added to the grocery list; planning and recorded spending remain user-confirmed. `NearbyStores` launches a real maps search rather than displaying simulated store data. Cloud sync, shared lists, pantry quantities, serving-aware planning, favorites and preferences are implemented; production services need the setup described in SERVICES_SETUP.md. Native store subscriptions remain disabled until real products and server verification are configured. See [the Home design](home-design.md) for behavior and screenshots.

## Serving-aware state and sync

Legacy meal strings remain readable. Catalog meals now store `@miga:ID:SERVINGS`
in the same versioned plan map; titles are resolved for the current language.
`RecipeAmounts` holds physical quantities for two servings and scales to the
selected portions. Grocery generation sums ingredient quantities, subtracts pantry
stock once, and tracks generated products separately from manual items. Package
counts are derived only when a compatible package basis is known.

`HomeDetails` adds optional preferences, pantry, favorites, serving defaults,
reference prices and grocery-link settings. Missing fields use backward-compatible
defaults. Reference prices are explicitly scoped by currency.

`HouseholdStateStore` lets the production store load/save plan and household data
atomically. `CloudSync` stores one durable account document and a pending revision.
Legacy local keys are imported without deletion. An RPC performs authenticated CAS
updates; conflicts require an explicit choice. SQL and functions are in `supabase/`.
The app keeps each tab mounted in an `IndexedStack` so search/filter/editor state
survives navigation. Account-sensitive data is separated by UUID.

Subscription events are never an entitlement by themselves. Edge Functions validate
store identity and current subscription state, and only server roles can persist
entitlements. See the setup and implementation checklist for external validation
and release work that code-only tests cannot complete.
