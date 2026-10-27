# Shareloop – Data Schema (v2.0 · Laravel API)

The data lives in the Laravel API's database (SQLite in development, MySQL in
production). Tables use snake_case columns (`donor_id`); the API's JSON uses the
camelCase field names below, which are what the app models read.
Photos are uploaded to the API and stored as `/api/files/…` paths; the API
returns full URLs.

Timestamps are ISO-8601 UTC strings (`2026-10-26T06:00:00.000Z`) set by the
server. Ids are strings; ULIDs unless stated.

```
users/{uid}                                     table users
categories/{categoryId}                         table categories
items/{itemId}                                  table items (20-char id made by the app)
needs/{needId}                                  table needs
requests/{itemId}_{requesterUid}                table share_requests (one per item per user)
reviews/{requestId}_{reviewerUid}               table reviews (one per person per exchange)
reports/{targetType}_{targetId}_{reporterUid}   table reports (one per person per target)
notifications/{notificationId}                  table notifications
```

Badges, eco points (10 × donations + 2 × requests), ratings and the leaderboard
are computed in the app — see lib/models/badge.dart. The average rating is stored on the user by the API when a review is saved.

---

## users/{uid}  (created on first OTP sign-in; profile fields filled by `POST /api/users`)
| Field | Type | Notes |
|---|---|---|
| uid | string | same as doc ID |
| displayName | string | |
| email | string \| null | optional |
| phone | string \| null | `+94…` OTP login |
| photoUrl | string \| null | uploaded photo URL (folder `shareloop/users/{uid}`) |
| role | string | `donor` \| `requester` \| `both` \| `admin` (admin set manually only) |
| language | string | `en` \| `si` \| `ta` |
| district | string | e.g. `Gampaha` |
| points | number | admin-managed (leaderboard) |
| badges | array<string> | admin-managed |
| donationCount | number | server adds +1 when a donation is completed |
| monthKey | string | UTC month of the last donation, e.g. `2026-10` (monthly leaderboard) |
| monthDonations | number | donations in `monthKey`; +1 same month, reset to 1 in a new month (server) |
| requestCount | number | server adds +1 per request sent |
| rating | number | avg from reviews |
| isBanned | bool | admin only |
| createdAt | datetime | |
| lastActiveAt | datetime | |

## categories/{categoryId}
| Field | Type | Notes |
|---|---|---|
| name | map | `{en, si, ta}` |
| icon | string | icon key used in Flutter |
| order | number | display order |

Seeded by `backend/database/seeders/CategorySeeder.php` (`php artisan migrate --seed`).

## items/{itemId}
| Field | Type | Notes |
|---|---|---|
| donorId | string | users uid |
| title | string | |
| description | string | |
| categoryId | string | books (Educational Books) · school (School Supplies) · clothes · shoes · electronics · household (Household Items) · other |
| condition | string | `new` \| `good` \| `used` |
| images | array<string> | photo URLs (max 5, folder `shareloop/items/{itemId}`) |
| district | string | for location filtering |
| city | string | |
| status | string | `available` \| `reserved` \| `donated` \| `removed` |
| requestCount | number | +1 by requester's app when requesting |
| createdAt | datetime | |
| updatedAt | datetime | |

## requests/{requestId}
| Field | Type | Notes |
|---|---|---|
| itemId | string | |
| itemTitle | string | denormalized for list views |
| donorId | string | |
| requesterId | string | |
| message | string | reason for request (5–500 chars) |
| antiResellAgreed | bool | must be `true` — "I confirm that I will not resell this donated item." |
| handoverMethod | string \| null | `direct` \| `courier` \| `on_demand` (PickMe Flash / Uber) — set by either side after acceptance |
| status | string | `pending` \| `accepted` \| `rejected` \| `cancelled` \| `completed` |
| createdAt | datetime | |
| updatedAt | datetime | |

Doc ID = `{itemId}_{requesterUid}` (one request per item per user). When the donor
selects one requester, every other pending request for that item is auto-declined
in the same database transaction and those requesters are notified.

## needs/{needId}  ("Item Requests" — post what you need)
| Field | Type | Notes |
|---|---|---|
| requesterId | string | must be the signed-in user with a requester role |
| title | string | 3–80 chars |
| description | string | ≤ 1000 chars |
| reason | string | why it is needed, 5–500 chars |
| categoryId | string | same ids as items |
| district / city | string | |
| status | string | `open` \| `fulfilled` \| `closed` (owner only) |
| antiResellAgreed | bool | must be `true` |
| createdAt | datetime | |

## reviews/{reviewId}
| Field | Type | Notes |
|---|---|---|
| requestId | string | one review per completed request |
| reviewerId | string | |
| revieweeId | string | |
| rating | number | 1–5 |
| comment | string | |
| createdAt | datetime | |

## reports/{reportId}
| Field | Type | Notes |
|---|---|---|
| reporterId | string | |
| targetType | string | `user` \| `item` |
| targetId | string | |
| reason | string | `spam` \| `resell` \| `fraud` \| `inappropriate` \| `other` |
| details | string | |
| evidence | array<string> | photo URLs |
| status | string | `open` \| `reviewing` \| `resolved` \| `dismissed` |
| createdAt | datetime | |

## notifications/{notificationId}  (written by the server, in the same transaction as the request change)
| Field | Type | Notes |
|---|---|---|
| userId | string | recipient |
| senderId | string | must be the signed-in user |
| type | string | `new_request` \| `request_accepted` \| `request_rejected` \| `request_cancelled` \| `request_completed` \| `need_match` |
| title | string | |
| body | string | |
| requestId | string | sender & recipient are always the two sides of this request |
| itemId | string | |
| needId | string | only for `need_match` (a donor shared an item for your need) |
| read | bool | created `false`; recipient may only change this field |
| createdAt | datetime | |

---

## Status flow

```
items:     available ──(donor accepts a request)──▶ reserved ──(donor completes)──▶ donated
requests:  pending ──▶ accepted ──▶ completed
              │──▶ rejected   (donor)
              └──▶ cancelled  (requester)
```

App code: `lib/controllers/request_controller.dart` → `lib/services/request_service.dart` → API `backend/app/Http/Controllers/Api/ShareRequestController.php` (transactions).
