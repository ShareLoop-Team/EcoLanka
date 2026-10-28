# EcoLanka (Shareloop) — Development Log

**Last updated:** 26 October 2026

## Sprint status

| Phase | Owner | Status |
|---|---|---|
| Phase 1 — Firebase project, Firestore, Auth (Google/Phone), schema, repo | Dulum | ✅ Done → replaced by Laravel API (26 Oct) |
| Phase 2 — Language/onboarding, phone + OTP login, profile setup | Kavidu / Dulum | ✅ Done (real Firebase OTP) |
| Phase 2 — Home dashboard, Explore & categories, search, navigation | Kavidu | ✅ Done (live Firestore data) |
| Phase 2 — Auth security, rules, roles (donor / requester / both / admin) | Rumanga | ✅ Done |
| Phase 3 — Share item, item details, request item, request details | Kavidu | ✅ Done |
| Phase 3 — Notifications (in-app), request flow without Cloud Functions | Dulum | ✅ Done |
| Phase 3 — Upload validation, anti-spam, anti-resell | Rumanga | ✅ Done |
| Phase 3 — Profile, history, badges, leaderboard, edit profile | Kavidu / Dulum | ✅ Done |
| Phase 3 — Reports collection, reporting system, admin review, fraud rules | Dulum / Rumanga | ✅ Done |
| QA — unit tests + manual test plan | Umayanga | ✅ Tests written · ⏳ manual run (docs/QA_TEST_PLAN.md) |
| Handover — architecture & deployment docs, security report | Dulum / Rumanga | ✅ docs/ARCHITECTURE.md, docs/SECURITY_REPORT.md |
| Handover — screenshots & demo video | Kavidu | ⏳ To do |
| Docs alignment — needs, anti-resell declaration, donor selection, handover options, Bronze→Platinum tiers, monthly leaderboard, Near me, si/ta strings | Dulum (all) | ✅ Done |
| Course notes — MVC controllers, repositories (DIP), roles (ISP/LSP), handover (OCP), DRY, tests | Dulum / Umayanga | ✅ Done (docs/DESIGN_PRINCIPLES.md) |

## 26 Oct 2026 — Firebase removed, Laravel backend
- New Laravel 12 REST API in `backend/` (Sanctum tokens, SQLite/MySQL): phone OTP,
  users, items, needs, requests, reviews, reports, notifications, photo uploads.
  All former `firestore.rules` checks are enforced server-side; 23 PHPUnit tests.
- App: Firebase / Cloudinary packages and config removed (`firebase_options.dart`,
  `google-services.json`, `firebase.json`, Firestore rules/scripts). Services now
  call the API through `lib/services/api_client.dart`.

## Still to do before the deadline
1. Host the API (HTTPS + MySQL) and build the app with `--dart-define=API_BASE_URL=…`
2. Real SMS: Notify.lk keys in `backend/.env` (`SMS_DRIVER=notifylk`)
3. Run the manual test plan with two accounts, then record the demo

## Earlier log (2 Sep 2026)
- Onboarding, welcome, phone number screens; PrimaryButton widget; Flutter web fixes.
