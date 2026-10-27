# Shareloop – Shared GitHub Repo & Project Structure

Owner: **Dulum (Infra)** — Phase 1 team task

## 1. Create the repository

1. GitHub → **New repository** → name `shareloop` → **Private** → add README.
2. *Settings → Collaborators* → invite **Kavidu, Rumanga, Umayanga** (Write access).
3. *Settings → Branches → Add rule* for `main`:
   - Require a pull request before merging (1 approval)
   - Do not allow force pushes

## 2. Repository layout

The Flutter app lives at the repo root; the Laravel API sits beside it in `backend/`.

```
EcoLanka/
├── lib/
│   ├── main.dart               # restore API session + providers + router
│   ├── config/                 # app_config (API URL), router, theme, constants
│   ├── models/                 # AppUser, Item, ShareRequest
│   ├── services/               # api_client + auth, user, item, need, request, review, report, notification, image
│   ├── providers/ controllers/ # app state
│   ├── views/                  # screens (auth, common, home, items, requests, profile)
│   ├── widgets/                # shared UI
│   └── l10n/                   # en / si / ta
├── backend/                    # Laravel REST API (Dulum)
│   ├── app/                    # controllers, models, OTP + SMS services
│   ├── routes/api.php          # every endpoint
│   ├── database/               # migrations + seeders
│   └── tests/                  # PHPUnit feature tests (Rumanga reviews)
├── docs/                       # INFRA.md, SCHEMA.md, GITHUB_SETUP.md
├── assets/ android/ ios/ web/ windows/ test/
└── pubspec.yaml
```

Run the app: start the API (`backend/start-backend.bat` or `php artisan serve`), then `flutter pub get` and `flutter run -d chrome` (or an Android device).
Run the API: `cd backend && php artisan serve` (see backend/README.md).

## 3. Branch strategy

| Branch | Owner | Purpose |
|---|---|---|
| `main` | everyone (via PR) | always runnable, demo-ready |
| `dev` | everyone | integration branch — feature PRs merge here |
| `feature/infra-*` | Dulum | Laravel API, migrations, deployment |
| `feature/security-*` | Rumanga | rules, validation |
| `feature/ui-*` | Kavidu | screens & flows |
| `test/*` | Umayanga | test cases, fixes found in QA |

Flow: `feature/*` → PR → `dev` → (Day 14 integration) → `main`.

Commit prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `test:`.

## 4. Secrets — never commit

- `serviceAccountKey.json`
- `backend/.env` (APP_KEY, SMS API keys, DB password)
- `.env` files
- Android keystore (`*.jks`, `key.properties`)

`google-services.json` / `GoogleService-Info.plist` are OK in a private repo (they're client config, not secrets).
