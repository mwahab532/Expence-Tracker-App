# Flutter Expense Tracker

A personal expense tracker built with Flutter and Firebase — email/password auth, expense CRUD with receipts, custom categories, search/filter/sort, statistics, a monthly budget with live remaining-balance tracking, dark mode, offline awareness, and centralized error handling throughout.

Package name: `flutter_expence_tracker`

---

## Features

- **Authentication** — email/password sign up, login, forgot password, logout, persisted session, self-healing profile creation (see [Architecture Decisions](#architecture-decisions))
- **Dashboard** — total / today's / this month's expenses, transaction count, pull-to-refresh
- **Budget** — set/edit/clear a monthly budget, live "remaining budget" card derived from actual spending, over-budget warning state
- **Expense management** — add, edit, delete, view details; optional receipt photo (Firebase Storage)
- **Categories** — default categories seeded on sign-up, plus create/rename/delete custom categories
- **Search & filters** — search by title, filter by category and date range, sort by amount or date
- **Statistics** — spending by category (pie chart), highest/lowest expense, average daily spend, monthly total
- **Profile** — edit display name, change password, dark/light theme toggle
- **Offline handling** — Firestore offline persistence (cached reads, queued writes), a live connectivity banner, and a one-time snackbar on connection change
- **Centralized error handling** — see [Error Handling](#error-handling) below

---

## Project Setup

1. Install the Flutter SDK and run:
   ```
   flutter pub get
   ```
2. Install the FlutterFire CLI and connect your Firebase project:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This regenerates `lib/firebase_options.dart` with your project's real values (the version in this repo should never be committed with placeholder values).
3. In the Firebase Console, enable:
   - **Authentication → Email/Password**
   - **Firestore Database**
   - **Storage**
4. Deploy Firestore and Storage security rules (see [Firebase Configuration](#firebase-configuration)).
5. Run the app:
   ```
   flutter run
   ```

---

## Firebase Configuration

### Firestore schema

Everything lives under a per-user subtree — no top-level collection is ever queried across users, which keeps security rules simple (one ownership check covers the whole subtree) and queries small.

```
/users/{uid}                         profile: email, displayName, photoUrl, monthlyBudget
/users/{uid}/expenses/{expenseId}    title, amount, categoryId, categoryName, date,
                                      notes, receiptImageUrl, createdAt, updatedAt
/users/{uid}/categories/{categoryId} name, isDefault, iconKey, createdAt
```

The budget is stored as a single `monthlyBudget` field directly on the user doc (via merge writes), rather than a separate collection — it's one value with no history requirement, so a subcollection would be overkill.

### Security rules (Firestore)

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;

      match /expenses/{expenseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /categories/{categoryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Security rules (Storage)

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /receipts/{userId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId
                          && request.resource.size < 5 * 1024 * 1024
                          && request.resource.contentType.matches('image/.*');
    }
    match /profile_pictures/{userId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId
                          && request.resource.size < 3 * 1024 * 1024
                          && request.resource.contentType.matches('image/.*');
    }
  }
}
```

### Queries

Category filter, date-range filter, and amount/date sort all run server-side via Firestore `where`/`orderBy` (`ExpenseRepository.watchExpenses`). Title search runs client-side on the already-filtered result set, since Firestore has no native substring search. Combined filter+sort queries may require a composite index — Firestore throws a direct console link for creating one the first time an unindexed combination runs in debug mode.

---

## Architecture

**Layered, MVVM-flavored:**

```
Screens (UI)
   ↓
Controllers / Providers (ViewModel layer — ChangeNotifier)
   ↓
Repositories (business logic, interfaces in domain/Repositries.dart)
   ↓
Services (thin Firebase wrappers)
   ↓
Firebase SDKs
```

Rules that keep the layering honest:
- Screens never import `firebase_auth`, `cloud_firestore`, or `firebase_storage` directly.
- All four repository interfaces (`AuthRepository`, `BudgetRepository`, `CategoryRepository`, `ExpenseRepository`) live together in `lib/domain/Repositries.dart`, each with a single `*Imp` implementation under `lib/data/repositories/`.
- Repositories return a typed `Result<T>` (`core/utils/result.dart`) — either data or a `Failure` (`core/errors/failures.dart`) — so the UI/provider layer never has to catch a raw `FirebaseException`.
- Screen-specific business logic (form validation, save orchestration) that doesn't belong in a shared provider is pulled into a dedicated controller instead of living in the widget — e.g. `screens/expenses/expence _controller.dart` for the add/edit expense form, `screens/auth/controllers/login_con.dart` for login, `screens/statistics/expense_statistics.dart` for the pure-Dart statistics aggregation used by `Statistics_body.dart`.
- Models (`ExpenseModel`, `CategoryModel`, `AppUserModel`, `BudgetModel`) are strongly typed with explicit `fromMap`/`toMap`, never raw `Map<String, dynamic>` passed around the app.

## State Management: Provider

- `MultiProvider`/`ProxyProvider` chains in `app/app.dart` wire services → repositories → app-wide providers once; screens read state via `context.watch`/`context.read`. This chain **is** the app's dependency injection mechanism — no separate service locator.
- `ExpenseProvider`, `CategoryProvider`, and `BudgetProvider` are scoped to the signed-in `uid` and created inside `DashboardScreen`/`dashboard_shell.dart`, so they're torn down cleanly on sign-out and never leak data between sessions.
- `AuthProvider`, `ThemeProvider`, and `Network_conectivity_provider.dart`'s `ConnectivityProvider` are app-wide and session-independent — registered above the auth gate, since login screens and offline detection matter before a user is signed in.

## Folder Structure

```
lib/
  app/                    root App widget, provider wiring
  core/
    constants/            Firestore collection names, default categories
    errors/                Failure types
    theme/                  ThemeData
    utils/                  Result<T>, safe_call.dart (see Error Handling)
    widgets/                shared widgets (AuthGate, SummaryCard)
  data/
    models/                 ExpenseModel, CategoryModel, AppUserModel, BudgetModel
    repositories/           *_Imp.dart implementations
    services/               thin Firebase/plugin wrappers
  domain/
    Repositries.dart        all repository interfaces in one place
  providers/                ChangeNotifiers (ViewModel layer)
  routes/                    named routes + generator
  screens/                   one folder per feature area, each with its own
                              controller where the screen has real logic to
                              separate from its widget tree
```

## Packages Used

| Package | Purpose |
|---|---|
| firebase_core / firebase_auth / cloud_firestore / firebase_storage | Backend |
| provider | State management + dependency injection |
| fl_chart | Statistics pie chart |
| intl | Currency/date formatting |
| cached_network_image | Receipt/profile image caching |
| shared_preferences | Persist theme choice |
| connectivity_plus | Live online/offline detection |
| uuid | Unique Storage file names |

---

## Error Handling

Error handling follows one consistent pattern everywhere instead of being handled ad hoc per screen:

1. **Repositories never throw.** Every write method catches its Firebase-specific exception first (`FirebaseAuthException`, `FirebaseException`) and falls back to a generic `catch (_)`, always returning a `Result<T>` — success or a typed `Failure`.
2. **`core/utils/safe_call.dart`** is a single shared helper every provider write method routes through: it adds a 15-second timeout and a catch-all around the repository call, so a provider method can never hang forever or throw an unhandled exception into the UI — even if a repository's own catch block were ever incomplete. This replaced several places where the same timeout/try-catch pattern had been copy-pasted (and had drifted out of sync) across `ExpenseProvider`, `CategoryProvider`, and `Buget_provider.dart`.
3. **Self-healing sign-up.** `auth_repository_Imp.dart`'s `_ensureUserProfile()` runs on both `signUp` and `signIn`. If a sign-up ever partially fails after the Firebase Auth account was already created (network drop mid-signup, misconfigured rules, etc.), the next successful login detects the missing Firestore profile/categories and recreates them — instead of leaving an unrecoverable account with no way to fix it through the UI.
4. **Global-level safety net.** `main.dart` wraps startup in `runZonedGuarded`, sets `FlutterError.onError` and `PlatformDispatcher.instance.onError`, and wraps `Firebase.initializeApp()` in its own try/catch with a dedicated startup-error screen — so nothing that slips past every layer above crashes the app silently with no user-facing feedback.
5. **Offline awareness.** `contectivity_servics.dart` + `Network_conectivity_provider.dart` track connectivity live; `offline_Banner.dart` shows a persistent banner while offline plus a one-time snackbar on the online/offline transition. Firestore's offline persistence means reads/writes keep working from cache regardless — this is purely about making that state visible instead of silent.

## Assumptions

- Single-currency app (USD symbol hardcoded in formatting).
- Deleting a custom category does not touch expenses that already used it — the category name is denormalized onto each `ExpenseModel` at write time, so historical expenses keep their original category label even after the category document is deleted.
- Budget is a single recurring monthly figure with no per-month history; "remaining budget" is always calculated fresh from the current month's expenses rather than stored and manually decremented, so it can never drift out of sync from actual spending.
- `connectivity_plus` reports network interface state, not verified internet reachability (e.g. Wi-Fi connected with no internet still reports "online") — a known limitation of the package, not of this implementation.

## Known Gaps / Next Steps

- **Change Profile Picture** is still a TODO in `profile_screen.dart` — needs `image_picker` + `StorageService.uploadFile` + `FirebaseAuth.updatePhotoURL`.
- No crash-reporting SDK wired in yet (`main.dart`'s `FlutterError.onError` has a commented hook for Crashlytics/Sentry).
- No automated tests yet — the repository-interface/implementation split in `domain/Repositries.dart` was specifically designed to make repositories mockable for provider-level unit tests when that's added.
- CSV/PDF export, pagination for long expense lists, and multi-currency support are not implemented.

## Git History

Commit regularly with meaningful messages throughout development — a project with only one or two commits at submission doesn't reflect how it was actually built.
