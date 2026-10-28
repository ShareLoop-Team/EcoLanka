# Security Report — Shareloop / EcoLanka

Owner: **Rumanga (Security)** · Enforcement: `backend/app/Http/Controllers/Api/` · Tests: `backend/tests/Feature/`

## 1. Threat model

The Flutter app is untrusted: a modified app or a script can call the API
directly. So **the Laravel API is the security boundary** — every write is
validated and permission-checked on the server, inside a database transaction
where several rows change together. The app's own checks are only for user
experience.

## 2. Authentication

| Control | Implementation |
|---|---|
| Phone OTP sign-in | 6-digit code, stored hashed (bcrypt), single use, expires after 5 minutes |
| OTP brute force | max 5 wrong guesses per code; app lockout after 3 wrong codes |
| SMS abuse | max 5 codes per number per hour + 10 requests/min per IP; only `+947XXXXXXXX` numbers accepted |
| Session | Laravel Sanctum personal access token (hashed in the DB), sent as `Authorization: Bearer`; revoked on sign-out |
| Auth required | Every route except `/auth/*`, `/health` and `/files/*` requires a token |
| Client validation | Sri Lankan mobile prefix regex (`70–78`), 30 s resend cooldown |

## 3. Roles & access control

| Role | Can share items | Can request items | Moderation |
|---|---|---|---|
| donor | ✅ | ❌ | ❌ |
| requester | ❌ | ✅ | ❌ |
| both | ✅ | ✅ | ❌ |
| admin (`php artisan shareloop:make-admin`) | ✅ | ✅ | ✅ reports, remove items, ban users |

- Users can switch between donor / requester / both, but can **never make themselves admin**.
- Banned users (`isBanned`, set only by admins) can't create items, needs or requests.

## 4. Data integrity

| Data | Protection |
|---|---|
| users | Only `displayName`, `district`, `language`, `photoUrl`, `role` are editable by the owner; counters, rating, points, badges and ban are server-managed |
| items | Donor = signed-in user; title 3–80, description 1–1000; condition `new/good/used`; known category; ≤ 5 images; new items start `available` with 0 requests; status changes only by donor or admin |
| requests | id `<itemId>_<uid>` → **one request per item per user**; donor is taken from the item; item must be `available`; reason 5–500; only valid status transitions (below); counters and notifications written in the same transaction |
| reviews | one per person per **completed** exchange, only by its two sides; reviewee is the other side; rating 1–5 |
| reports | one per person per target; fixed reason list; only admins list / update |
| notifications | created only by the server; users read and mark only their own |

Request status transitions:

```
donor:     pending → accepted | rejected      accepted → completed
requester: pending | accepted → cancelled  (an accepted item becomes available again)
```

## 5. Anti-spam & anti-resell

- **Anti-resell:** listings mentioning prices or sales are rejected **in the app** (`AntiResellPolicy`) **and in the API** (`App\Support\Api::looksLikeSale`, same pattern). Users can report items with the reason "resell".
- **Anti-resell declaration:** requests and needs require `antiResellAgreed: true`.
- **Anti-spam:** deterministic ids block duplicate requests, reviews and reports (HTTP 409). Rate limiting on all routes.
- **Handover method:** only the donor or requester of an *accepted* request, only `direct` / `courier` / `on_demand`.
- **Need-match notifications:** only from the donor of the item to the poster of that need.
- **Contact privacy:** the app shows phone numbers only after a request is accepted.

## 6. Upload security (images)

- `POST /api/uploads` needs a token; only `jpg, jpeg, png, webp, gif`, max 5 MB, validated as an image.
- Folder must match `items/<id>`, `users/<own uid>` or `reports/<id>`; random file names.
- `GET /api/files/…` rejects `..` paths and serves only the public upload disk.
- The app compresses photos (max width 1280, quality 70), at most 5 per item.

## 7. Fraud prevention & reporting

- Report items or users from item details or request details.
- Admins review reports in the app (Profile → Admin: reports): remove an item, ban a user, resolve or dismiss.
- Reviews are tied to completed requests, so ratings can't be faked without a real exchange.

## 8. Known limitations / recommendations

1. No push notifications when the app is closed (the app polls while open). Add FCM or a WebSocket server (Laravel Reverb) later if needed.
2. Serve the API over HTTPS only in production and remove Android cleartext traffic.
3. Uploaded files are public by URL (random names). Fine for item photos; keep evidence uploads in mind.

## 9. Final audit checklist

- [x] All data routes require a token
- [x] No client can self-promote to admin or edit counters / points / badges / ban
- [x] Request / review / report duplicates blocked by id
- [x] Status transitions restricted per role
- [x] Anti-resell enforced server-side
- [x] Notifications can't be forged (server-written only)
- [x] Covered by `php artisan test`
- [ ] HTTPS + real SMS provider (before release)
