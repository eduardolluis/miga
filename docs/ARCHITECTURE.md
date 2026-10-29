# Miga Architecture

## Overview

Miga is a cross-platform mobile app built with Flutter for Android and iOS.

The first version is planned to work without a user account or a custom backend. Recipes and initial app data will be bundled with the app, and user preferences will be stored on the device.

## Current project structure

- `lib/`: Flutter application code.
- `assets/`: Images and other bundled resources.
- `docs/`: Product and technical documentation.
- `test/`: Automated tests.
- `android/` and `ios/`: Native platform configuration.

## Planned app flow

1. The user selects household size and meal preferences.
2. Miga creates a weekly meal plan from its recipe data.
3. The user views recipes and can replace planned meals.
4. Miga creates a shopping list from the selected meals.
5. The user can explore nearby grocery stores on a map.


## App entry point

- `lib/main.dart` starts the Flutter application.
- `lib/app.dart` configures the app, including its theme and initial screen.

## Data and services

### Recipes and meal plans

The initial recipe catalog will be included in the app. The first meal-planning version should work without a paid AI service.

### Local data

The first version is planned to store preferences and saved plans on the device. Cloud sync and user accounts are outside the initial scope.

### Maps and store locations

A map provider may be used to display nearby grocery stores. The provider and its pricing must be reviewed before implementation.

### Price comparison

Store prices require reliable, up-to-date data. Miga will only compare prices when that data is available. The source of price data is still undecided.

### AI

Gemini may be evaluated later for meal-plan generation. Any API key must be kept outside the mobile app, and the app must remain usable if AI is unavailable.

## Decisions still to make

- Which map provider to use.
- How to obtain and update store prices.
- Whether users can submit price updates.
- What local storage solution to use.
- Whether a backend is needed after the first version.
