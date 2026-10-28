# QA Test Plan & Report — Shareloop / EcoLanka

Owner: **Umayanga (QA)**

## Automated tests

```bash
flutter test
```

| File | Covers |
|---|---|
| `test/validators_test.dart` | anti-resell detection, title/description/message limits, SL mobile numbers, names |
| `test/badges_and_models_test.dart` | Bronze/Silver/Gold/Platinum tiers, monthly counters, AppUser roles, formatters, 7 categories, New/Good/Used |
| `test/solid_domain_test.dart` | ISP/LSP roles, OCP handover methods, anti-resell policy, district locator |
| `test/controller_test.dart` | Item/Request/Need controllers with fake repositories (DIP) |

## Test accounts

| Phone | Code | Use as |
|---|---|---|
| +94 77 000 0001 | 123456 | Donor (role: Both) |
| +94 77 000 0002 | 123456 | Requester (role: Both) |

Use two browsers (for example Chrome and an Incognito window), or a phone and the web, to test both sides at once.

## Manual test cases

Fill in the **Result** column (Pass / Fail + bug id) while testing.

### A. Authentication
| # | Steps | Expected | Result |
|---|---|---|---|
| A1 | Language → onboarding → welcome → enter 770000001 → Send code | Moves to OTP screen | |
| A2 | Enter 123456 | Signed in → profile setup (first time) | |
| A3 | Enter wrong code 3× | "Invalid OTP" then lockout message | |
| A4 | Enter 731234567 | Send button stays disabled (invalid prefix) | |
| A5 | Complete profile (name, district, role) | Lands on Home; `GET /api/users/{uid}` returns the profile | |
| A6 | Close and reopen app | Splash skips onboarding → Home | |
| A7 | Profile → Sign out | Back to Welcome | |

### B. Home & Explore
| # | Steps | Expected | Result |
|---|---|---|---|
| B1 | Open Home with no items | Empty state + "Share an item" button | |
| B2 | Items exist | Cards show photo/placeholder, title, location, condition | |
| B3 | Tap a category | Explore opens filtered to that category | |
| B4 | Search "book" on Home | Explore opens with matching items | |
| B5 | Explore: district + condition filters | List updates correctly | |
| B6 | Own items | Not shown in your own feed | |

### C. Share item
| # | Steps | Expected | Result |
|---|---|---|---|
| C1 | + → fill form → Post | Item detail opens; item appears for other user | |
| C2 | Title "Chair for sale" | Validation error (anti-resell) | |
| C3 | Add 6 photos | Max 5 kept | |
| C4 | Role = Requester, tap + | Message: switch role to share | |
| C5 | Add 1–5 photos and post | Photos upload to the API and show on the item | |

### D. Request flow (two accounts)
| # | Steps | Expected | Result |
|---|---|---|---|
| D0 | Request without ticking the anti-resell box | Send button disabled | |
| D1 | Requester: item → Request → reason → tick declaration → Send | Request detail (Pending); donor gets banner + bell badge | |
| D2 | Requester requests same item again | Button shows "View my request" | |
| D3 | Donor: Requests → Received → Accept | Status Accepted; item Reserved; requester notified | |
| D4 | After accept | Both see each other's phone number | |
| D5 | Donor: Mark as handed over | Completed; item Donated; donor donations +1 | |
| D6 | Donor rejects another request | Requester sees Rejected + notification | |
| D7 | Requester cancels pending request | Cancelled; donor notified | |
| D8 | Request message "hi" | Validation error (min 5 chars) | |
| D9 | Two requesters request one item; donor selects one | Other request auto-declined + notified | |
| D10 | Accepted request → choose Courier | Both see method + safety tips | |

### E. Reviews, profile, badges
| # | Steps | Expected | Result |
|---|---|---|---|
| E1 | Completed request → Leave a review (4★) | Saved; button changes to "You reviewed" | |
| E2 | Review same request again | Not possible | |
| E3 | Profile | Name, role, district, stats, rating stars | |
| E4 | Edit profile → change district/role | Saved; Home location updates | |
| E5 | Badges | Bronze at 5 donations, progress bar to Silver (10) | |
| E6 | Leaderboard → This month / All time | Donors ranked; you highlighted; month resets | |
| E7 | History | Donated items + sent requests listed | |

### H. Needs ("Item Requests") & Near me
| # | Steps | Expected | Result |
|---|---|---|---|
| H1 | + → Post a need (title, reason, tick declaration) | Need appears in Explore → Needs | |
| H2 | Donor opens need → "I have this — share it" | Share form pre-filled; poster gets "need_match" notification | |
| H3 | Owner → Mark fulfilled / Close | Need leaves the open list | |
| H4 | Explore → Use my location | District set to nearest; items sorted by distance | |
| H5 | Donor-only role | "Post a need" disabled | |

### F. Notifications & reports
| # | Steps | Expected | Result |
|---|---|---|---|
| F1 | Bell → Notifications | List newest first; unread highlighted | |
| F2 | Tap a notification | Opens request; marked read; badge decreases | |
| F3 | Mark all read | Badge clears | |
| F4 | Item → flag → Report (Resell) | "Report sent" | |
| F5 | Report same item again | "You already reported this" | |
| F6 | Admin (role set in console) → Admin: reports | Sees reports; Remove item / Ban user work | |

### G. Security checks (should FAIL with permission-denied)
| # | Attempt | Expected | Result |
|---|---|---|---|
| G1 | Edit own `users.role` to `admin` in a script | Denied | |
| G2 | Set `donationCount` +5 | Denied | |
| G3 | Create a request for your own item | Denied | |
| G4 | Non-admin reads `reports` | Denied | |
| G5 | Write a notification to an unrelated user | Denied | |
| G6 | Create a request with `antiResellAgreed: false` | Denied | |
| G7 | Set `monthDonations` to 10 | Denied | |

## Bug report template

| ID | Screen | Steps to reproduce | Expected | Actual | Severity | Status |
|---|---|---|---|---|---|---|
| BUG-001 | | | | | High / Med / Low | Open |
