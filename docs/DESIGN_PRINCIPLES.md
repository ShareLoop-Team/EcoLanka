# Design Principles — how Shareloop follows the course notes

Maps the Shareloop proposal/documentation and the course notes (SOLID 1–5, DRY,
Standards & Rules, Best Practices, Geolocation) to the code.

## Feature matrix (Shareloop documentation → code)

| Feature in the docs | Where in the app |
|---|---|
| Item listing (photos, category, condition New/Good/Used, district) | `views/items/create_post_screen.dart`, `controllers/item_controller.dart` |
| Item Requests — post a need with a reason | `views/needs/*`, `controllers/need_controller.dart`, `needs` collection |
| Request with reason + anti-resell declaration | `views/requests/create_request_screen.dart`, `utils/anti_resell_policy.dart` |
| Donor selects one requester; others auto-declined | `RequestController.accept` → `ApiRequestService.accept` → `POST /requests/{id}/accept` (one DB transaction) |
| Handover: direct / courier / PickMe Flash | `models/handover_method.dart`, request detail screen |
| Badges Bronze 5 · Silver 10 · Gold 25 · Platinum 50 | `models/badge.dart` (`AchievementEngine`) |
| Monthly + all-time leaderboard | `UserController.monthlyLeaderboard`, `views/profile/badges_screen.dart` |
| Near me (GPS → nearest district, sort by distance) | `utils/district_locator.dart`, `services/location_service.dart` |
| Sinhala / Tamil / English | `lib/l10n/*.arb` |
| Reports & admin review | `controllers/report_controller.dart`, `views/admin/` |

## SOLID

| Principle | Example |
|---|---|
| **S** — Single responsibility | Views only draw; controllers hold rules (validation, request ids, counters); services only talk to the REST API. `AntiResellPolicy` only detects sale wording. |
| **O** — Open/closed | `HandoverMethod` is abstract; adding e.g. "Post office" = one new subclass in `HandoverMethods.all`, no screen changes. Badge tiers are data in `AchievementEngine`. |
| **L** — Liskov substitution | Every `UserRole` (donor, requester, both, admin) can be used wherever a `UserRole` is expected (`test/solid_domain_test.dart`). Fake repositories replace the API ones in tests. |
| **I** — Interface segregation | Capabilities `ItemViewer`, `ItemDonor`, `ItemRequester`, `PlatformModerator`; a donor never gets requester methods. Repositories are split per collection instead of one big "DatabaseService". |
| **D** — Dependency inversion | Controllers depend on `lib/repositories/repositories.dart` (abstract). `lib/config/dependencies.dart` is the only place that knows the API service classes. |

## DRY

- Categories, conditions, districts, status labels: one place (`utils/helpers.dart`).
- Validation messages: `utils/validators.dart`, reused by every form and controller.
- Request/review/report ids built by one function each (`RequestController.requestIdFor`, …).
- Shared widgets: `ItemCard`, `NeedCard`, `RequestCard`, `UserBadge`, `app_widgets.dart`.
- Form fields: `widgets/app_text_field.dart` (`AppTextField`) used by the item, need,
  request, review, report and edit-profile forms; buttons: `PrimaryButton`.

## Standards & best practices

- `flutter_lints` + `analysis_options.yaml`; files `snake_case`, classes `PascalCase`.
- Streams created once per screen (`late final`) — no re-subscribing on rebuild.
- `context` is not used after `await` without a `mounted` check.
- Security enforced twice: in controllers (UX) and in the Laravel API (trust).

## Geolocation

`geolocator` asks for coarse location only once, on "Use my location". The
position is converted to the nearest of the 25 district centres
(`DistrictLocator.nearestDistrict`, haversine) — exact GPS is never stored.
