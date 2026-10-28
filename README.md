# EcoLanka (Shareloop)

A free donation app for Sri Lanka: share items you no longer need, post what you need, and track your impact with badges. Flutter app + Laravel REST API. Phone sign-in codes are sent by the API (via httpSMS from an Android phone), with Firebase Authentication available as an alternative.

> **Development status:** Working end-to-end prototype. Phone sign-in uses the API's own SMS codes (httpSMS) by default, or Firebase Authentication; listings, requests, profiles, reviews, reports and notifications are stored in the Laravel API in `backend/`. A demo seeder fills the app with sample users, items and activity. Not yet deployed to production (see [Limitations and next steps](#limitations-and-next-steps)).

Docs: [Architecture](docs/ARCHITECTURE.md) · [Schema](docs/SCHEMA.md) · [Security](docs/SECURITY_REPORT.md) · [QA plan](docs/QA_TEST_PLAN.md) · [Design principles](docs/DESIGN_PRINCIPLES.md) · [Infra](docs/INFRA.md) · [API reference](backend/README.md) · [Progress](PROGRESS.md)

## Contents

- [About](#about)
- [Current features](#current-features)
- [Technology](#technology)
- [Application structure](#application-structure)
- [Prerequisites](#prerequisites)
- [Setup and run](#setup-and-run)
- [Continuous integration](#continuous-integration)
- [Tests](#tests)
- [DRY refactoring](#dry-refactoring)
- [Limitations and next steps](#limitations-and-next-steps)
- [Contributing](#contributing)
- [Team](#team)
- [License](#license)
- [Project link](#project-link)

## About

EcoLanka is a local sharing app where people give away usable items, ask for what they need, and connect with neighbours to hand items over. Donors post items with photos; requesters ask for them with a reason and an anti-resell declaration; the donor picks one requester, they agree on a handover method, and both sides review each other after the exchange.

## Current features

- Language selection (English, Sinhala, Tamil), onboarding, phone sign-in with a 6-digit SMS code (sent by the API through httpSMS, or by Firebase), profile setup with role (donor / requester / both) and district.
- Home feed and Explore with search, category, condition and district filters, plus "Near me" sorting by district distance.
- Share an item with up to 5 photos (uploaded to the API); anti-resell check blocks price / sale wording in the app and on the server.
- "Item requests" (needs): post what you need and why; donors can answer with a matching item.
- Request flow: request with a reason → donor accepts one requester (others are declined automatically) → choose a handover method (direct, courier, on-demand) → mark completed → two-way star reviews.
- In-app notifications with live updates, history, badges (Bronze 5 · Silver 10 · Gold 25 · Platinum 50), eco points, all-time and monthly leaderboards.
- Reporting of users and items, with an admin screen to review reports, remove items and ban users.

## Technology

| Technology | Use |
|---|---|
| Flutter and Dart | Cross-platform app (Android, iOS, web, Windows). Package **ecolanka** 0.1.0+1, Dart SDK **^3.12.2**. |
| httpSMS | Sends the API's sign-in codes as normal SMS from an Android phone (`SMS_DRIVER=httpsms`). |
| Firebase Authentication | Optional phone sign-in (`--dart-define=AUTH_PROVIDER=firebase`) — project `shareloop-c2157`. |
| Laravel 12 + Sanctum | REST API, bearer-token sessions, validation and permission checks (`backend/`). |
| SQLite / MySQL | API database (SQLite for development, MySQL for production). |
| http | App ↔ API requests and photo uploads (`lib/services/api_client.dart`). |
| Provider, GoRouter | App state and navigation. |
| Flutter localization + intl | English, Sinhala and Tamil strings. |
| SharedPreferences | Saved language and API session on the device. |
| geolocator, image_picker | Nearest-district detection and photo picking. |
| Google Fonts, Pinput, flutter_animate | Typography, OTP input, animations. |

## Application structure

MVC with Dependency Inversion. Views never talk HTTP; they call controllers, which depend on repository interfaces. `lib/config/dependencies.dart` is the one place that wires the real API / Firebase / Geolocator services in (tests pass fakes instead).

~~~mermaid
flowchart LR
    V[Views & widgets] --> C[Controllers]
    C --> R[Repository interfaces]
    S[Services] -. implement .-> R
    S --> API[Laravel API<br/>backend/]
    S -. optional .-> FA[Firebase Auth<br/>phone OTP]
    FA -- ID token --> API
    API --> DB[(SQLite / MySQL)]
    API --> SMS[httpSMS<br/>Android phone]
~~~

Sign-in (default): the app calls `POST /api/auth/send-code`; the API creates a 6-digit code and sends it by SMS through httpSMS, then `POST /api/auth/verify` checks it and returns the API session. With `AUTH_PROVIDER=firebase`, Firebase sends and verifies the code instead and the app exchanges Firebase's ID token at `POST /api/auth/firebase`. Everything else is the Laravel API. Screens keep using `StreamBuilder`: `ApiClient.watch()` polls endpoints and refetches straight after each write.

### Directory overview

~~~text
.
├── backend/                 # Laravel 12 API: routes, controllers, migrations, seeders, tests
├── lib/
│   ├── config/              # app config (API URL), router, theme, constants, dependencies
│   ├── models/              # user, role, item, need, request, handover, rating, badge, report, notification
│   ├── controllers/         # auth, user, item, need, request, review, report, notification
│   ├── repositories/        # abstract interfaces the controllers depend on
│   ├── services/            # api_client + Firebase auth, REST API and Geolocator implementations
│   ├── utils/               # validators, formatters, anti-resell policy, district locator, helpers
│   ├── views/               # auth, common, home, items, needs, requests, profile, notifications, admin
│   ├── widgets/             # shared cards, buttons, text field, badges, empty/error/loading views
│   └── l10n/                # English, Sinhala and Tamil strings
├── test/                    # Flutter tests
├── docs/                    # architecture, schema, security, QA, infra
├── android/ ios/ web/ windows/
└── pubspec.yaml
~~~

Security is enforced twice: in the controllers (for the user experience) and in the Laravel API (the real boundary). See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/SECURITY_REPORT.md](docs/SECURITY_REPORT.md).

## Prerequisites

- Flutter stable with a Dart SDK satisfying **^3.12.2**.
- PHP 8.2+ with `pdo_sqlite`, `mbstring`, `openssl`, `fileinfo` (and `gd` for the upload tests), plus Composer.
- A Flutter target: Chrome for web, Android SDK / emulator or a phone with USB debugging, Xcode on macOS for iOS.

~~~sh
flutter doctor
flutter devices
~~~

## Setup and run

1. **Start the API** (in `backend/`). On Windows you can double-click `backend\start-backend.bat`, or:

   ~~~sh
   cd backend
   composer install
   cp .env.example .env && php artisan key:generate
   php artisan migrate --seed
   php artisan db:seed --class=DemoSeeder   # optional: demo users, items with photos, activity
   php artisan serve --host=0.0.0.0 --port=8000
   ~~~

2. **Install the app packages:**

   ~~~sh
   flutter pub get
   ~~~

3. **Run the app:**

   ~~~sh
   flutter run -d chrome                                                # API at http://localhost:8000/api
   flutter run                                                          # Android emulator → http://10.0.2.2:8000/api
   flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000/api   # real phone on the same Wi-Fi
   ~~~

4. **Sign in** with a test number (no SMS is sent): `+94 77 000 0001` (Nimal in the demo data) or `+94 77 000 0002` (Kavya), code `123456`. Test numbers are listed in `OTP_TEST_NUMBERS` in `backend/.env`.

5. **Send real SMS codes with httpSMS** (optional). Install the httpSMS app on an Android phone with a SIM, sign in at [httpsms.com](https://httpsms.com), copy the API key from Settings, then set in `backend/.env`:

   ~~~ini
   SMS_DRIVER=httpsms
   HTTPSMS_API_KEY=your-key
   HTTPSMS_FROM=+947XXXXXXXX     # the phone number of the httpSMS phone
   ~~~

   Run `php artisan config:clear` and restart the API. Each code is a normal SMS from that phone, so the phone must stay on and online, and your mobile plan's SMS rates apply. If sending fails, the app shows "We could not send the SMS right now" and the code is discarded. With `SMS_DRIVER=log` (the default) codes are only written to `storage/logs/laravel.log`.

   **Firebase instead:** build the app with `--dart-define=AUTH_PROVIDER=firebase`. Test numbers must then be listed in the Firebase console (Authentication → Sign-in method → Phone → Phone numbers for testing); debug builds (or `--dart-define=FIREBASE_TEST_PHONES=true`) skip app verification for those numbers, and real numbers on Android also need the app's SHA-1/SHA-256 in Firebase.

Location is coarse only and is used to find the nearest district; if permission is denied the user picks a district by hand. To edit localization strings, update the ARB files in `lib/l10n/` and run `flutter gen-l10n`.

Full API reference: [backend/README.md](backend/README.md).

## Continuous integration

`.github/workflows/ci.yml` runs on pushes and pull requests to `main`: `flutter pub get` + `flutter test --coverage` (coverage uploaded to Codecov; an upload failure does not fail the job), and a second job that installs the Laravel dependencies and runs `php artisan test`.

## Tests

~~~sh
flutter test                     # app
flutter analyze                  # static checks
cd backend && php artisan test   # API
~~~

| Test file | Covers |
|---|---|
| `test/validators_test.dart` | form validation, anti-resell wording, Sri Lankan phone numbers |
| `test/controller_test.dart` | item, request and need controllers with fake repositories |
| `test/solid_domain_test.dart` | roles (ISP/LSP), handover methods (OCP), district locator |
| `test/badges_and_models_test.dart` | badges, model mapping, formatters, lookups |
| `test/api_services_test.dart` | API client and API sign-in: session, error mapping, live polling streams |
| `backend/tests/Feature/*` | SMS code sign-in (httpSMS), Firebase token sign-in, roles, items, needs, request flow, reviews, reports, uploads |

Manual test cases are in [docs/QA_TEST_PLAN.md](docs/QA_TEST_PLAN.md).

## DRY refactoring

Duplication removed so each rule or piece of UI lives in one place:

- **Text fields** — the item, need, request, review, report and edit-profile forms use one `AppTextField` (`lib/widgets/app_text_field.dart`); styling comes from the theme's `InputDecorationTheme`.
- **Buttons** — primary actions use one `PrimaryButton` (`lib/widgets/custom_button.dart`).
- **Validation** — every form and controller uses `lib/utils/validators.dart`.
- **Lookups** — categories, conditions, districts and status labels are defined once in `lib/utils/helpers.dart`.
- **Theme** — lives only in `lib/config/theme.dart`.
- **Data access** — HTTP calls sit in services behind repository interfaces (one shared `ApiClient`), so no screen repeats queries.
- **Screen states** — loading, empty and error views are shared widgets (`lib/widgets/app_widgets.dart`).

## Limitations and next steps

- The API is not yet deployed: it needs an HTTPS host and MySQL, and the app must be built with `--dart-define=API_BASE_URL=…`.
- Real SMS codes depend on one Android phone running httpSMS; for larger volumes switch to a Sri Lankan SMS gateway (a `notifylk` driver is included). With Firebase sign-in, real numbers need the Firebase SMS region policy for Sri Lanka and the app's SHA-1/SHA-256.
- No push notifications while the app is closed (the app polls while open).
- Production Android signing: the release build still uses the debug signing configuration, and `android:usesCleartextTraffic` must be removed once the API uses HTTPS.
- Not every visible string is localized yet.

## Contributing

1. Create a focused branch from `main`.
2. Match the existing structure (views → controllers → repositories → services) and keep credentials out of source control (`backend/.env` is ignored).
3. Run `flutter pub get`, `flutter analyze`, `flutter test` and `php artisan test` (in `backend/`).
4. Open a pull request with a concise summary and the checks you ran.

## Team

Dulum (Infra) · Kavidu (UI/Dev) · Rumanga (Security) · Umayanga (QA) · Chamara

## License

No LICENSE file was found in the repository. The project license has not been specified.

## Project link

- [EcoLanka on GitHub](https://github.com/ShareLoop-Team/EcoLanka)
