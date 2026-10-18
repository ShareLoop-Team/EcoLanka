# EcoLanka (Shareloop)

Item sharing & donation app for Sri Lanka — Flutter + Firebase (free Spark plan).

## Run

```bash
flutter pub get
flutter run -d chrome        # or: flutter run  (Android device/emulator)
```

Sign in with a test number (no SMS sent): **+94 77 000 0001**, code **123456**.

## Project layout

| Path | What's there |
|---|---|
| `lib/` | Flutter app — `services/` talk to Firebase & Cloudinary, `views/` are screens |
| `backend/` | Firebase config: Firestore rules, indexes, seed script |
| `docs/INFRA.md` | Backend setup & deployment (Firebase project `shareloop-c2157`) |
| `docs/SCHEMA.md` | Firestore collections and status flow |
| `docs/GITHUB_SETUP.md` | Branch strategy & repo structure |
| `PROGRESS.md` | Development log |

## Deploy Firestore rules & indexes

```bash
npm install -g firebase-tools
firebase login
cd backend
firebase deploy --only firestore:rules,firestore:indexes
```
