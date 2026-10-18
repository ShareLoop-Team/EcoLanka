# Shareloop – Firestore Collection Schema (v1.1, finalized Phase 1 · free Spark plan)

Images are stored on **Cloudinary**; Firestore only keeps their HTTPS URLs.

All timestamps are Firestore `Timestamp` (use `FieldValue.serverTimestamp()`).
All IDs are auto-generated unless stated.

```
users/{uid}
categories/{categoryId}
items/{itemId}
requests/{requestId}
reviews/{reviewId}
reports/{reportId}
notifications/{notificationId}
```

---

## users/{uid}  (doc ID = Firebase Auth UID)
| Field | Type | Notes |
|---|---|---|
| uid | string | same as doc ID |
| displayName | string | |
| email | string \| null | Google login |
| phone | string \| null | `+94…` OTP login |
| photoUrl | string \| null | Cloudinary URL (folder `shareloop/users/{uid}`) |
| role | string | `donor` \| `requester` \| `both` \| `admin` (admin set manually only) |
| language | string | `en` \| `si` \| `ta` |
| district | string | e.g. `Gampaha` |
| points | number | admin-managed (leaderboard) |
| badges | array<string> | admin-managed |
| donationCount | number | app adds +1 on completed donation (rules allow only +1) |
| requestCount | number | app adds +1 per request sent (rules allow only +1) |
| rating | number | avg from reviews |
| isBanned | bool | admin only |
| createdAt | timestamp | |
| lastActiveAt | timestamp | |

## categories/{categoryId}
| Field | Type | Notes |
|---|---|---|
| name | map | `{en, si, ta}` |
| icon | string | icon key used in Flutter |
| order | number | display order |

Seeded by `scripts/seed_categories.js`.

## items/{itemId}
| Field | Type | Notes |
|---|---|---|
| donorId | string | users uid |
| title | string | |
| description | string | |
| categoryId | string | |
| condition | string | `new` \| `like_new` \| `good` \| `fair` |
| images | array<string> | Cloudinary URLs (max 5, folder `shareloop/items/{itemId}`) |
| district | string | for location filtering |
| city | string | |
| status | string | `available` \| `reserved` \| `donated` \| `removed` |
| requestCount | number | +1 by requester's app when requesting |
| createdAt | timestamp | |
| updatedAt | timestamp | |

## requests/{requestId}
| Field | Type | Notes |
|---|---|---|
| itemId | string | |
| itemTitle | string | denormalized for list views |
| donorId | string | |
| requesterId | string | |
| message | string | reason for request |
| status | string | `pending` \| `accepted` \| `rejected` \| `cancelled` \| `completed` |
| createdAt | timestamp | |
| updatedAt | timestamp | |

## reviews/{reviewId}
| Field | Type | Notes |
|---|---|---|
| requestId | string | one review per completed request |
| reviewerId | string | |
| revieweeId | string | |
| rating | number | 1–5 |
| comment | string | |
| createdAt | timestamp | |

## reports/{reportId}
| Field | Type | Notes |
|---|---|---|
| reporterId | string | |
| targetType | string | `user` \| `item` |
| targetId | string | |
| reason | string | `spam` \| `resell` \| `fraud` \| `inappropriate` \| `other` |
| details | string | |
| evidence | array<string> | Cloudinary URLs |
| status | string | `open` \| `reviewing` \| `resolved` \| `dismissed` |
| createdAt | timestamp | |

## notifications/{notificationId}  (written by the app, in the same batch as the request change)
| Field | Type | Notes |
|---|---|---|
| userId | string | recipient |
| senderId | string | must be the signed-in user |
| type | string | `new_request` \| `request_accepted` \| `request_rejected` \| `request_cancelled` \| `request_completed` |
| title | string | |
| body | string | |
| requestId | string | rules check sender & recipient are the two sides of this request |
| itemId | string | |
| read | bool | created `false`; recipient may only change this field |
| createdAt | timestamp | |

---

## Status flow

```
items:     available ──(donor accepts a request)──▶ reserved ──(donor completes)──▶ donated
requests:  pending ──▶ accepted ──▶ completed
              │──▶ rejected   (donor)
              └──▶ cancelled  (requester)
```

App code for every transition: `lib/services/request_service.dart`.
