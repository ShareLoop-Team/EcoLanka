# Shareloop – Infrastructure

> Backend: Laravel REST API in `backend/` · App-side services in `lib/services/`.

Owner: **Dulum (Infra)**

The app used to run on Firebase (Auth + Firestore + rules) and Cloudinary.
Everything now runs on our own Laravel API:

| Need | Before | Now |
|---|---|---|
| Phone OTP sign-in | Firebase Auth | `POST /api/auth/send-code` + `/verify`, Sanctum bearer tokens |
| Database | Cloud Firestore | SQLite (dev) / MySQL (prod) via Eloquent |
| Security rules | `firestore.rules` | Validation + permission checks in the API controllers |
| Counters / status changes | batched client writes | one DB transaction per action on the server |
| Image uploads | Cloudinary unsigned preset | `POST /api/uploads` → `storage/app/public`, served by `GET /api/files/…` |
| Notifications | `notifications` collection snapshots | `notifications` table, app polls `GET /api/notifications` |

| File | Purpose |
|---|---|
| `backend/routes/api.php` | Every endpoint |
| `backend/app/Http/Controllers/Api/` | Validation, permissions, business rules |
| `backend/database/migrations/` | Tables (see `docs/SCHEMA.md`) |
| `backend/database/seeders/` | Categories (`CategorySeeder`) and demo data (`DemoSeeder`) |
| `backend/app/Services/OtpService.php` | OTP codes, expiry, attempt limits, test numbers |
| `backend/app/Services/Sms/` | SMS drivers: `log` (dev) and `notifylk` |
| `backend/tests/` | PHPUnit feature tests |
| `lib/services/api_client.dart` | HTTP client, saved session, polling streams |

## Local setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan db:seed --class=DemoSeeder   # optional demo users / items
php artisan serve --host=0.0.0.0 --port=8000
```

On Windows double-click `backend\start-backend.bat`.

## Test phone numbers

Set in `backend/.env` → `OTP_TEST_NUMBERS`. No SMS is sent for these.

| Phone | Code |
|---|---|
| +94 77 000 0001 | 123456 |
| +94 77 000 0002 | 123456 |

Other numbers: with `SMS_DRIVER=log` the code appears in
`backend/storage/logs/laravel.log`.

## Real SMS (Notify.lk)

1. Create an account at https://notify.lk and get the User ID, API key and an
   approved Sender ID.
2. In `backend/.env`: `SMS_DRIVER=notifylk`, `NOTIFYLK_USER_ID=…`,
   `NOTIFYLK_API_KEY=…`, `NOTIFYLK_SENDER_ID=…`.
3. Remove `OTP_TEST_NUMBERS` in production.

Another provider: add a class implementing `App\Services\Sms\SmsSender` and
bind it in `AppServiceProvider`.

## Admins

```bash
php artisan shareloop:make-admin +94770000001
```

## Pointing the app at the API

`lib/config/app_config.dart` picks `http://localhost:8000/api` (web/desktop) or
`http://10.0.2.2:8000/api` (Android emulator). For a real phone or a deployed
server pass `--dart-define=API_BASE_URL=…`.

## Production checklist

- [ ] HTTPS domain for the API; `APP_ENV=production`, `APP_DEBUG=false`
- [ ] MySQL database (`DB_CONNECTION=mysql`, `DB_*`), `php artisan migrate --force --seed`
- [ ] Real SMS driver; no test numbers; `OTP_EXPOSE_CODE=false`
- [ ] Back up the database and `storage/app/public` (photos)
- [ ] Remove `android:usesCleartextTraffic` from the Android manifest
