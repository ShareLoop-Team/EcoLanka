# EcoLanka

A Flutter prototype for a community item-sharing experience in Sri Lanka. The app presents an onboarding flow and sample listings intended to make sharing usable household items easier.

> **Development status:** This repository currently contains a UI prototype. Phone verification uses a simulated request and a hard-coded demo OTP, and the home feed displays sample data. There is no connected authentication provider, database, or production listing workflow.

## Contents

- [About](#about)
- [Current features](#current-features)
- [Screenshots](#screenshots)
- [Technology](#technology)
- [Application structure](#application-structure)
- [Prerequisites](#prerequisites)
- [Setup and run](#setup-and-run)
- [Tests](#tests)
- [Limitations and next steps](#limitations-and-next-steps)
- [Contributing](#contributing)
- [Authors and acknowledgements](#authors-and-acknowledgements)
- [License](#license)
- [Project link](#project-link)

## About

EcoLanka explores a local sharing app where people can discover items, connect with neighbors, and reuse goods. The current code focuses on the Flutter interface and navigation flow, including language selection, onboarding, phone-number entry, OTP entry, profile setup, and a sample home screen.

The intended users are people who want to share or find reusable items in their local community. Listing discovery, exchange coordination, and user accounts are design goals; the current repository does not yet connect these flows to a backend.

## Current features

- Splash, language-selection, onboarding, welcome, phone-number, OTP, profile-setup, and home screens.
- English, Sinhala, and Tamil localization resources, with language preference saved locally.
- Sri Lankan mobile-number format validation in the phone-number screen.
- A four-digit OTP screen with resend cooldown and attempt-limit UI. The code is simulated; the demo verification code in the source is **1234**.
- A sample home feed with category and search UI and two hard-coded item cards.
- Local district state managed with Provider.
- Material 3 theme, reusable UI widgets, and animated interface elements.

These are prototype behaviors. Search, category controls, notifications, item requests, and bottom navigation do not currently connect to a listing service or backend.

## Screenshots

The repository does not currently include verified screenshots of the running app. No screenshots are shown here.

## Technology

| Technology | Use in the current code |
|---|---|
| Flutter and Dart | Cross-platform application UI. The package is **ecolanka**, version **0.1.0+1**; the Dart SDK constraint is **^3.12.2**. |
| Material 3 | App theme and Material components. |
| Provider | In-memory district and language state. |
| GoRouter | Navigation between prototype screens. |
| Flutter localization and intl | Generated English, Sinhala, and Tamil localization resources. |
| SharedPreferences | Stores the selected language on the device. |
| Google Fonts | Inter text theme. |
| Pinput | OTP input interface. |
| flutter_animate | Screen and element animations. |

The dependency file also declares **http** and **geolocator**; the current app does not use them for a connected API or location-search workflow. Firebase is not declared in the published pubspec.yaml.

## Application structure

The app uses a single Flutter client. main.dart initializes local providers and localization, then starts a MaterialApp.router. GoRouter maps URLs to screens. The language provider reads and writes the selected locale with SharedPreferences; the user provider holds district state in memory. The item controller is currently an empty placeholder.

~~~mermaid
flowchart TD
    Main[main.dart] --> Providers[Provider: user and language state]
    Main --> Router[GoRouter]
    Router --> Startup[Splash and onboarding screens]
    Router --> Account[Phone, demo OTP, profile setup]
    Router --> Home[Sample home feed]
    Language[LanguageProvider] --> Preferences[SharedPreferences]
    Localization[Generated en / si / ta resources] --> Screens[Localized interface]
~~~

### Directory overview

~~~text
.
├── android/                 # Android project
├── ios/                     # iOS project
├── web/                     # Web project
├── windows/                 # Windows project
├── assets/images/            # App and onboarding image assets
├── lib/
│   ├── config/               # Router, theme, and shared constants
│   ├── controllers/          # Item controller placeholder
│   ├── l10n/                 # ARB and generated localization files
│   ├── providers/             # In-memory user and language state
│   ├── views/                 # Onboarding, account, and home screens
│   └── widgets/               # Shared UI widgets
├── test/                     # Flutter tests
├── analysis_options.yaml
└── pubspec.yaml
~~~

## Prerequisites

- Flutter stable with a Dart SDK satisfying the **^3.12.2** constraint in pubspec.yaml.
- Git.
- A configured Flutter target: Android SDK for Android, Xcode on macOS for iOS, Chrome for Web, or the Windows desktop toolchain for Windows.

Check the installed toolchains and available devices with:

~~~sh
flutter doctor
flutter devices
~~~

## Setup and run

Clone the repository and install its Dart and Flutter dependencies:

~~~sh
git clone https://github.com/EcoLanka-App/EcoLanka.git
cd EcoLanka
flutter pub get
~~~

Run on a connected device or emulator:

~~~sh
flutter run
~~~

Or choose a target explicitly:

~~~sh
flutter run -d chrome
flutter run -d <device-id>
~~~

No environment file, Firebase project, database, or API key is required by the current code. Phone verification is simulated, so running the app does not send an SMS.

To edit localization strings, update the ARB files in lib/l10n/ and regenerate the localization output:

~~~sh
flutter gen-l10n
~~~

## Tests

Run the repository's Flutter tests with:

~~~sh
flutter test
~~~

The tracked test file contains a sample assertion. It does not test authentication, remote data, listing behavior, or end-to-end app flows. This README does not claim that tests have been run.

## Limitations and next steps

The published code does not yet include:

- Real phone authentication or server-side OTP delivery and validation. The current OTP is a client-side demo value and must not be used for real accounts.
- A backend, database, persistent user accounts, or real item listings.
- Working item creation, item requests, donor/borrower exchange flow, notifications, or moderation.
- Functional search and category filters over listing data.
- Location permissions, distance calculations, or map-based discovery.
- Complete localization of every visible string.
- Production Android signing. The Android release build currently references the debug signing configuration.

These items describe gaps in the current source, not completed features or guaranteed roadmap commitments.

## Contributing

1. Fork the repository and create a focused branch.
2. Make changes that match the existing Flutter structure and keep credentials out of source control.
3. Run flutter pub get, flutter analyze, and flutter test.
4. Open a pull request with a concise summary and the checks you ran.

## Authors and acknowledgements

The repository files inspected for this README do not identify project authors or institutional affiliations. Add verified credits here when the maintainers provide them.

## License

No LICENSE file was found in the repository. The project license has not been specified.

## Project link

- [EcoLanka on GitHub](https://github.com/EcoLanka-App/EcoLanka)
