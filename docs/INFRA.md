# Shareloop – Infrastructure (Phase 1, free Spark plan)

> Lives in the EcoLanka repo: Firebase config in `backend/`, app-side services in `lib/services/`.

Owner: **Dulum (Infra)** · Firebase project: **`shareloop-c2157`**

This version runs entirely on Firebase's **free Spark plan** — no card needed.

| Need | Paid (Blaze) way | What we use instead (free) |
|---|---|---|
| Image uploads | Firebase Storage | **Cloudinary** free tier (25 GB) |
| Push notifications | Cloud Functions + FCM | App writes `notifications/` docs → listener shows a **local notification** |
| Counters / status changes | Cloud Functions | App does them in **batched writes**, guarded by `firestore.rules` |

Limits to know: real SMS OTP is capped at **10/day** (use the test numbers), and notifications appear while the app is open or in the background — not when it has been force-closed. To move to Blaze later, see `backend/blaze-upgrade/README.md`.

| File | Purpose |
|---|---|
| `backend/firebase.json` / `backend/.firebaserc` | Firebase CLI config (Firestore + emulators), project `shareloop-c2157` |
| `backend/firestore.rules` | Starter rules — auth required, role-aware, guards app-side writes (Rumanga hardens) |
| `backend/firestore.indexes.json` | Composite indexes for Explore / History / Requests / Notifications |
| `docs/SCHEMA.md` | Firestore collection schema + status flow |
| `docs/GITHUB_SETUP.md` | Shared repo, branch strategy, project structure |
| `lib/services/` | auth (phone OTP), database (profiles), cloudinary, request flow, notifications |
| `backend/scripts/seed_categories.js` | Seeds the `categories` collection |
| `backend/blaze-upgrade/` | Storage rules + Cloud Functions, kept for if you upgrade later |

---

## Phase 1 checklist

- [x] 1. Firebase project created — `shareloop-c2157`
- [x] 2a. Firestore created — Production mode, `asia-south1`
- [x] 3a. Google + Phone sign-in enabled
- [ ] 3b. Add test phone numbers
- [ ] 4. Cloudinary account + upload preset (replaces Storage)
- [ ] 5. Add teammates as Editors
- [ ] 6. Deploy rules + indexes, seed categories
- [ ] 7. Connect Flutter app + SHA fingerprints (with Kavidu)
- [ ] Team: schema → `docs/SCHEMA.md` ✔ written · GitHub repo → `docs/GITHUB_SETUP.md`

---

## Step 3b — Test phone numbers

*Authentication → Sign-in method → Phone → Phone numbers for testing*

| Phone | Code |
|---|---|
| +94 77 000 0001 | 123456 |
| +94 77 000 0002 | 123456 |

No real SMS is sent and they don't count toward the 10/day limit. Give these to Umayanga for QA.

## Step 4 — Cloudinary (image storage)

1. Sign up free at https://cloudinary.com (no card).
2. Dashboard → copy your **Cloud name**.
3. *Settings (gear) → Upload → Upload presets → Add upload preset*
   - Preset name: `shareloop_unsigned`
   - Signing mode: **Unsigned**
   - Folder: `shareloop`
   - Allowed formats: `jpg, png, webp`
   - Incoming transformation: limit width to 1280 (`c_limit,w_1280`) to save space
   - Save.
4. Put the cloud name in `lib/config/app_config.dart` (`cloudinaryCloudName`).

Note: an unsigned preset means anyone who has the preset name can upload to it. That's normal for student/demo apps; the format and size limits above keep abuse small. Never put the Cloudinary **API secret** in the app.

## Step 5 — Teammates

*Project settings → Users and permissions → Add member* → Kavidu, Rumanga, Umayanga as **Editor**.

## Step 6 — Deploy rules + indexes, seed categories

Needs Node.js 18+ on your computer.

```bash
npm install -g firebase-tools
firebase login
cd backend
firebase deploy --only firestore:rules,firestore:indexes
```

Seed categories:
1. *Project settings → Service accounts → Generate new private key* → save as `backend/scripts/serviceAccountKey.json` (**never commit it**).
2. Run:
   ```bash
   cd backend/scripts
   npm install
   node seed_categories.js
   ```

Local testing with emulators (no internet / quota needed):
```bash
firebase emulators:start     # UI at http://localhost:4000
```

## Step 7 — Connect the Flutter app (with Kavidu)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=shareloop-c2157
```
This generates `lib/firebase_options.dart`.

Add SHA fingerprints (Google sign-in and phone OTP fail on Android without them):
```bash
cd android && ./gradlew signingReport
```
Copy SHA-1 and SHA-256 → *Project settings → Your apps → Android app → Add fingerprint*.

Firebase packages are already in `pubspec.yaml` (`firebase_core`, `firebase_auth`, `cloud_firestore`, `image_picker`).

Services already in the app (`lib/services/`):

| File | What it does |
|---|---|
| `auth_service.dart` | Phone OTP sign-in (mobile + web) — used by the phone/OTP screens |
| `database_service.dart` | Create/read the user profile — used by profile setup + splash |
| `cloudinary_service.dart` | Pick + upload images, returns URLs for `items.images` |
| `request_service.dart` | create / accept / reject / complete / cancel — each one batched write incl. the notification |
| `notification_service.dart` | Streams the user's notifications + unread count; `start(onNew)` for in-app banners |


Optional: for announcements to all users, *Engage → Messaging* in the Firebase console can send push campaigns on the free plan (needs `firebase_messaging` in the app).

## Handover to Rumanga (Security)

- Rules are deployed in starter form; he owns hardening `firestore.rules`.
- Because there are no Cloud Functions, the rules are the only thing protecting counters and notifications. Key checks already in place:
  - users can't change their own `role`, `points`, `badges`, `isBanned`; counters only +1
  - a request's `donorId` must match the item's real owner, item must be `available`
  - donor can only set accepted/rejected/completed; requester only cancelled
  - notifications: sender must be one side of the request, recipient the other; recipient can only flip `read`
- Role lives at `users/{uid}.role` (`donor` | `requester` | `admin`). Admins are set manually in the console.
- Image validation lives in the Cloudinary upload preset (formats, size), not in Firebase.
