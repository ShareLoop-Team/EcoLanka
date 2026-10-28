# Shareloop (EcoLanka) — Laravel API

REST backend for the Flutter app (replaces Firebase Auth, Cloud Firestore,
Firestore rules and Cloudinary). Laravel 12 · Sanctum bearer tokens · SQLite by
default (MySQL works too) · phone OTP sign-in · photo uploads.

## Run it locally

Requirements: PHP 8.2+ with `pdo_sqlite`, `mbstring`, `openssl`, `fileinfo`
(and `gd` for the upload tests), plus Composer.

```bash
cd backend
composer install            # skip if vendor/ is already there
cp .env.example .env        # Windows: copy .env.example .env
php artisan key:generate
php artisan migrate --seed                  # tables + categories
php artisan db:seed --class=DemoSeeder      # optional: 2 demo users, items, a need
php artisan serve --host=0.0.0.0 --port=8000
```

Windows shortcut: double-click `start-backend.bat` (does all of the above).

Then run the app (from the project root):

| Target | Command |
|---|---|
| Chrome | `flutter run -d chrome` (API: `http://localhost:8000/api`) |
| Android emulator | `flutter run` (API: `http://10.0.2.2:8000/api`) |
| Real phone on the same Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<your-PC-LAN-IP>:8000/api` |

Sign in with a test number — no SMS is sent:
`+94 77 000 0001` or `+94 77 000 0002`, code `123456` (set in `OTP_TEST_NUMBERS`).
For any other number the code is written to `storage/logs/laravel.log`
(`SMS_DRIVER=log`). Set `SMS_DRIVER=notifylk` and the `NOTIFYLK_*` keys to send
real SMS through [Notify.lk](https://notify.lk).

Make someone a moderator (they must have finished profile setup):

```bash
php artisan shareloop:make-admin +94770000001
```

## Tests

```bash
php artisan test
```

`tests/Feature` covers sign-in/OTP, profiles and roles, items and needs,
the full request → accept → complete → review flow, reports, notifications and
photo uploads. Each rule that used to live in `firestore.rules` has a test.

## Security model (was `firestore.rules`)

All checks run on the server; the app's own checks are only for the UX.

- Every route except `/auth/*`, `/health` and `/files/*` needs a bearer token.
- Users choose `donor`, `requester` or `both`; `admin` is only set with the
  artisan command (or by another admin). Counters, rating, points, badges and
  `isBanned` cannot be changed by the user.
- Banned users or the wrong role cannot post items / needs or send requests.
- Items: title 3–80, description 1–1000, condition `new|good|used`, ≤ 5
  photos, a known category, and no price / sale wording (anti-resell).
- Requests: id `{itemId}_{requesterId}` (one per item per user), reason 5–500,
  anti-resell declaration required, never on your own or an unavailable item.
  Allowed transitions only — donor: pending→accepted|rejected,
  accepted→completed; requester: pending|accepted→cancelled.
- Accept / complete / cancel run in one DB transaction with the item status,
  the counters and the notifications.
- Reviews: one per person per completed exchange, only by its two sides.
- Reports: one per person per target; only admins list or update them.
- Notifications: you only see and mark your own.
- OTP: 6 digits, 5-minute expiry, 5 wrong guesses max, 5 codes per number per
  hour, plus per-IP rate limiting.

## API reference

Base URL `…/api`. JSON in and out; field names match the app models
(`docs/SCHEMA.md`). Errors: `{"message": "...", "code": "..."}` with a 4xx status.

| Method & path | Body / query | Notes |
|---|---|---|
| `POST /auth/send-code` | `phone` (`+947XXXXXXXX`) | `debugCode` only if `OTP_EXPOSE_CODE=true` |
| `POST /auth/verify` | `phone`, `code` | → `token`, `uid`, `phone`, `hasProfile` |
| `GET /auth/me` · `POST /auth/logout` | | |
| `POST /users` | `displayName`, `district`, `role`, `language` | first-time profile |
| `GET /users/{uid}` · `PATCH /users/{uid}` | editable fields | 404 until profile exists |
| `GET /users/leaderboard` | `limit` | all-time donors |
| `GET /users/monthly` | `month` (`2026-10`) | donors this month |
| `GET /categories` | | |
| `GET /items` | `donorId`, `status` | newest first (150 max without `donorId`) |
| `POST /items` | `id?`, `title`, `description`, `categoryId`, `condition`, `images[]`, `district`, `city` | |
| `GET /items/{id}` · `PATCH /items/{id}/status` | `status` | donor or admin |
| `GET /needs` · `POST /needs` | `requesterId` · need fields + `antiResellAgreed` | |
| `GET /needs/{id}` · `PATCH /needs/{id}/status` | `status` | owner or admin |
| `POST /needs/{id}/match` | `itemId` | notifies the need's poster |
| `GET /requests` | `as=requester\|donor` or `itemId` | |
| `POST /requests` | `itemId`, `message`, `antiResellAgreed` | |
| `GET /requests/{id}` | | the two sides or admin |
| `POST /requests/{id}/accept\|reject\|complete\|cancel` | | |
| `PATCH /requests/{id}/handover` | `handoverMethod` (`direct\|courier\|on_demand`) | |
| `GET /reviews` · `GET /reviews/mine` · `POST /reviews` | `revieweeId` · `requestId` · `requestId`, `rating`, `comment` | |
| `POST /reports` · `GET /reports` · `PATCH /reports/{id}` | | list/update: admin |
| `GET /notifications` · `POST /notifications/{id}/read` · `POST /notifications/read` | `ids[]` | |
| `POST /uploads` (multipart) | `file`, `folder` (`items/{id}`, `users/{uid}`, `reports/{id}`) | → `url` |
| `GET /files/{path}` | | public, serves uploaded photos |

The app has no WebSocket: its streams poll these endpoints every few seconds
and refetch immediately after each write (`lib/services/api_client.dart`).

## Production notes

- Use HTTPS, set `APP_ENV=production`, `APP_DEBUG=false`, remove
  `OTP_TEST_NUMBERS`, keep `OTP_EXPOSE_CODE=false`, and set a real SMS driver.
- For MySQL set `DB_CONNECTION=mysql` and the `DB_*` values, then migrate.
- Remove `android:usesCleartextTraffic` from the Android manifest once the API
  is served over HTTPS.
