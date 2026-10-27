# Shareloop (EcoLanka)

Free donation app for Sri Lanka — share items you no longer need, post what you
need, and track your impact with badges. Flutter app + Laravel REST API,
with Firebase Authentication for phone sign-in.

Docs: [Architecture](docs/ARCHITECTURE.md) · [Schema](docs/SCHEMA.md) ·
[Security](docs/SECURITY_REPORT.md) · [QA plan](docs/QA_TEST_PLAN.md) ·
[Design principles](docs/DESIGN_PRINCIPLES.md) · [Infra](docs/INFRA.md) ·
[Progress](PROGRESS.md)

## Setup

Requirements: Flutter SDK (Dart `^3.12`), PHP 8.2+ (extensions `pdo_sqlite`,
`mbstring`, `openssl`, `fileinfo`), Chrome for web, Android Studio or a phone
with USB debugging for Android. Composer is optional (`backend/vendor.tgz`
ships the PHP dependencies).

1. Start the API (Laravel, in `backend/`) — on Windows double-click
   `backend\start-backend.bat`, or:

   ```bash
   cd backend
   composer install
   cp .env.example .env && php artisan key:generate
   php artisan migrate --seed
   php artisan db:seed --class=DemoSeeder   # optional demo users / items
   php artisan serve --host=0.0.0.0 --port=8000
   ```

2. Install the app packages:

   ```bash
   flutter pub get
   ```

3. Sign in with a Firebase test number (no SMS is sent): `+94 77 000 0001`
   or `+94 77 000 0002`, code `123456`.

   Phone sign-in uses **Firebase Authentication** (project `shareloop-c2157`,
   `lib/firebase_options.dart`); everything else is the Laravel API. After
   Firebase verifies the code, the app sends its ID token to
   `POST /api/auth/firebase`, which checks Google's signature and returns the
   API session. Test numbers must be listed in the Firebase console
   (Authentication → Sign-in method → Phone → Phone numbers for testing).
   Debug builds (or `--dart-define=FIREBASE_TEST_PHONES=true`) skip app
   verification for those numbers; real numbers on Android also need the app's
   SHA-1/SHA-256 in Firebase.

Full API reference: [backend/README.md](backend/README.md).

## Run

```bash
flutter run -d chrome                                            # API at http://localhost:8000/api
flutter run                                                      # Android emulator → http://10.0.2.2:8000/api
flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000/api   # real phone on the same Wi-Fi
```

`flutter devices` lists the connected devices. Location is coarse only and is
used to find the nearest district; if permission is denied the user picks a
district by hand.

## Architecture

MVC with Dependency Inversion. Views never talk HTTP; they call controllers,
which depend on repository interfaces. `lib/config/dependencies.dart` is the one
place that wires the real API / Geolocator services in (tests pass fakes instead).

```
View (lib/views, lib/widgets)
   ↓
Controller (lib/controllers)
   ↓
Repository interface (lib/repositories)
   ↑ implemented by
Service (lib/services) → Laravel REST API (backend/) · Geolocator
```

| Folder | Contents |
|---|---|
| `lib/config/` | app config (API URL), router (`go_router`), theme, constants, dependencies |
| `lib/models/` | user, role, item, need, request, handover method, rating, badge, report, notification |
| `lib/controllers/` | auth, user, item, need, request, review, report, notification |
| `lib/repositories/` | abstract interfaces the controllers depend on |
| `lib/services/` | `api_client` + REST API / Geolocator implementations |
| `lib/utils/` | validators, formatters, anti-resell policy, district locator, helpers |
| `lib/views/` | screens: auth, common, home, items, needs, requests, profile, notifications, admin |
| `lib/widgets/` | shared widgets (cards, buttons, text field, badges, empty/error/loading views) |
| `lib/l10n/` | English, Sinhala and Tamil strings |
| `backend/` | Laravel 12 API: routes, controllers, migrations, seeders, tests |

Security is enforced twice: in the controllers (for the user experience) and in
the Laravel API (the real boundary). See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for diagrams and request flow.

## Testing

```bash
flutter test                     # app
cd backend && php artisan test   # API
```

| Test file | Covers |
|---|---|
| `test/validators_test.dart` | form validation, anti-resell wording, Sri Lankan phone numbers |
| `test/controller_test.dart` | item, request and need controllers with fake repositories |
| `test/solid_domain_test.dart` | roles (ISP/LSP), handover methods (OCP), district locator |
| `test/badges_and_models_test.dart` | badges, model mapping, formatters, lookups |
| `test/api_services_test.dart` | API client: sign-in session, error mapping, live polling streams |
| `backend/tests/Feature/*` | OTP sign-in, roles, items, needs, request flow, reviews, reports, uploads |

Static checks: `flutter analyze`. CI (`.github/workflows/ci.yml`) runs
`flutter test --coverage` and `php artisan test` on every push. Manual test cases are in
[docs/QA_TEST_PLAN.md](docs/QA_TEST_PLAN.md).

## DRY Refactoring

Duplication removed so each rule or piece of UI lives in one place:

- **Text fields** — the item, need, request, review, report and edit-profile
  forms each built their own `TextFormField` + `InputDecoration`. They now use
  one `AppTextField` (`lib/widgets/app_text_field.dart`); styling comes from the
  theme's `InputDecorationTheme`.
- **Buttons** — primary actions use one `PrimaryButton`
  (`lib/widgets/custom_button.dart`) instead of repeating `ElevatedButton` styling.
- **Validation** — every form and controller uses `lib/utils/validators.dart`
  rather than writing its own checks.
- **Lookups** — categories, conditions, districts and status labels are defined
  once in `lib/utils/helpers.dart`.
- **Theme** — `lib/config/app_config.dart` used to hold a second copy of the
  theme; it now lives only in `lib/config/theme.dart`.
- **Data access** — HTTP calls sit in services behind repository
  interfaces (one shared `ApiClient`), so no screen repeats queries.
- **Screen states** — loading, empty and error views are shared widgets
  (`lib/widgets/app_widgets.dart`).

## Team

Dulum (Infra) · Kavidu (UI/Dev) · Rumanga (Security) · Umayanga (QA) · Chamara
