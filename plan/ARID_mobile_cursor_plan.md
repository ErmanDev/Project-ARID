# A.R.I.D. Mobile App — Cursor Build Plan

**A.R.I.D.** — Autonomous Risk Identification and Distribution Mapping of Dengue Vector Breeding Sites Using AI Vision and Geospatial Analysis

**Architecture principle: OFFLINE-FIRST.** Every core feature (capture, classify, tag GPS, save, view map, earn points) must work with zero internet connection. Firebase is a *sync target*, never a *runtime dependency*. If the app can't do something offline, redesign the feature until it can.

---

## 0. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter (Dart) | Cross-platform, matches thesis conceptual framework |
| Local DB | Isar (or Hive as fallback) | Fast, offline-first NoSQL, good with Flutter, supports queries needed for map/history |
| AI Model | TensorFlow Lite (.tflite) exported from Google Teachable Machine | Must run **on-device**, no API calls — this is non-negotiable for offline-first |
| Map (offline) | `flutter_map` + offline tile caching (`flutter_map_tile_caching`) | Leaflet-based, works offline once tiles are cached; swap for online Leaflet webview later if desired |
| GPS | `geolocator` package | Works offline (device GPS chip, not network location) |
| Cloud sync | Firebase (Firestore + Storage) | Only touched by a background sync service, never blocks UI |
| Connectivity detection | `connectivity_plus` | Triggers sync when online |
| State management | Riverpod (or Provider) | Keep it simple, one clear pattern throughout |
| Background sync | `workmanager` (Android) / native background tasks | Periodic + connectivity-triggered sync |

---

## 1. Theme / Color Palette

Based on the app icon (map pin + mosquito + blue-to-green map gradient), but **desaturated/muted** — not a literal match, just the same color family toned down so it reads as a clean utility app rather than a bright logo.

| Role | Color | Hex (approx) | Notes |
|---|---|---|---|
| Primary (brand) | Muted teal-blue | `#4A7A8C` | Nav bars, primary buttons, app bar |
| Secondary (brand) | Muted sage green | `#6B9080` | Accents, secondary buttons, success states |
| Alert / High Risk (Red marker) | Muted brick red | `#B5555A` | Red-risk markers, badges — softer than icon's bright red |
| Caution / Moderate Risk (Yellow) | Muted amber | `#C9A66B` | Yellow-risk markers only — keep off primary UI |
| Safe / Low Risk (Green marker) | Muted sage green | `#7C9C7C` | Same family as secondary, slightly desaturated for map markers |
| Background | Off-white / light grey | `#F5F5F3` | Main screen background |
| Surface / Cards | White | `#FFFFFF` | Cards, sheets |
| Text primary | Dark slate | `#2E3438` | Matches mosquito icon's dark navy, softened to near-charcoal |
| Text secondary | Grey | `#6E7477` | Captions, metadata, timestamps |
| Divider / Border | Light grey | `#E2E2E0` | Subtle borders only |

**Guidelines:**
- Reserve the three risk colors (red/yellow/green) **only** for risk-level indicators (markers, badges, report status) — never reuse them for generic UI elements, or users will confuse "this button is red" with "this is a high-risk report."
- Primary/secondary teal-and-sage carries the rest of the UI (buttons, nav, headers, icons) so the app has its own identity distinct from the risk-color system.
- No gradients in-app UI (unlike the icon) — flat, muted fills only, to keep the interface calm and legible in bright outdoor field conditions.
- Define these as a single `AppColors` / `ThemeData` file early (Milestone 1) so every screen pulls from it — don't hardcode hex values in widgets.

---

## 2. Data Model (local-first, sync-ready)

Design every record with sync metadata baked in from day one.

```
Report {
  id: String (UUID, generated on-device — never server-generated)
  imagePath: String (local file path)
  imageRemoteUrl: String? (null until uploaded)
  classification: enum { breeding, nonBreeding }
  confidenceScore: double
  riskLevel: enum { red, yellow, green }
  latitude: double
  longitude: double
  gpsAccuracy: double
  capturedAt: DateTime
  userId: String (local device/user id)
  pointsAwarded: int (0 until verified — see rewards section)
  syncStatus: enum { pendingUpload, uploading, synced, failed }
  lastSyncAttempt: DateTime?
}

UserProfile {
  id: String
  displayName: String
  totalPoints: int (locally accumulated, reconciled on sync)
  reportCount: int
  syncStatus: enum { local, synced }
}

SyncQueueItem {
  id
  reportId
  attemptCount: int
  lastError: String?
}
```

**Rule:** every write goes to Isar/Hive first. Firestore is only ever written to by the sync service, never directly by UI/business logic.

---

## 3. Milestones

### Milestone 1 — Project Scaffold & Offline Skeleton
- [ ] Flutter project init, folder structure (`lib/data`, `lib/domain`, `lib/services`, `lib/ui`, `lib/sync`)
- [ ] Set up Isar/Hive local DB, define schemas above
- [ ] Basic navigation shell: Home / Capture / Map / History / Rewards / Profile
- [ ] App works fully with Airplane Mode ON from this point forward — test after every milestone

### Milestone 2 — AI Classification (On-Device, Offline)
- [ ] Export trained model from Teachable Machine as **TFLite**
- [ ] Integrate `tflite_flutter` package
- [ ] Camera capture + gallery upload flow (`image_picker` or `camera` package)
- [ ] Run inference on-device, output classification + confidence score
- [ ] Map confidence score → risk level:
  - Breeding, high confidence → **Red**
  - Breeding, lower confidence → **Yellow**
  - Non-breeding → **Green**
  - (Pull your actual confidence thresholds from Chapter III methodology once you finalize them in testing)
- [ ] Save `Report` to local DB immediately after classification — **before** any network call

### Milestone 3 — GPS Tagging (Offline)
- [ ] `geolocator` integration, request permissions gracefully (explain why, handle denial)
- [ ] Capture lat/lng + accuracy at moment of image capture
- [ ] Attach to `Report` record locally
- [ ] Handle poor/no GPS signal gracefully (retry, manual pin-drop fallback if signal never resolves)

### Milestone 4 — Offline Map View
- [ ] `flutter_map` with color-coded markers (red/yellow/green) pulled from local DB — not Firestore
- [ ] Offline tile caching for the study area (pre-download tiles for known region, or cache-as-you-go)
- [ ] Marker tap → shows report detail (image, classification, confidence, timestamp)
- [ ] Filter by risk level / date range (all local queries)

### Milestone 5 — Local History & Report Management
- [ ] List view of all reports made by the user (synced + pending)
- [ ] Visual sync status indicator per report (pending / syncing / synced / failed)
- [ ] Allow manual retry of failed syncs
- [ ] Allow local edit/delete before sync (e.g., wrong GPS pin)

### Milestone 6 — Rewards / Points System (Local-First)
Per your Significance of the Study: verified reports earn points LGUs/barangays can use to recognize participants.

- [ ] Points awarded **locally and provisionally** at submission time (e.g., based on classification confidence or completeness of report) — so the user gets instant feedback even offline
- [ ] Mark points as `provisional` vs `verified`:
  - Provisional = counted instantly on-device
  - Verified = confirmed once synced and (optionally) reviewed server-side or cross-checked
- [ ] Local leaderboard/summary screen showing user's own point total and report count (device-local, no network needed to view)
- [ ] Decide + document your points rule set (e.g., +X for a report, bonus for red/high-confidence detections, streak bonuses) — flag this as a config table you can tune later without code changes
- [ ] Reward tiers/badges (optional, cosmetic, fully local)

### Milestone 7 — Connectivity & Sync Service
- [ ] `connectivity_plus` listener — detect online transition
- [ ] Background sync service (`workmanager`) triggers on:
  - App foreground + connectivity available
  - Periodic background check (e.g., every 15–30 min if app backgrounded)
  - Manual "Sync now" button in Settings/History
- [ ] Sync logic per `Report`:
  1. Upload image to Firebase Storage (if not already uploaded)
  2. Write/update Firestore document with image URL + metadata
  3. Update local `syncStatus` → `synced`
  4. Reconcile `pointsAwarded` (provisional → verified) if applicable
- [ ] Conflict handling: local record is source of truth until synced; use `id` (UUID) as the document key to avoid duplicate writes on retry
- [ ] Retry with backoff on failure; cap retries and surface failed items in History for manual retry
- [ ] Never block any UI interaction on sync — sync runs silently in the background

### Milestone 8 — Firebase Setup (Cloud Side)
- [ ] Firestore collections: `reports`, `users`
- [ ] Firebase Storage bucket for images (consider compressing images before upload to save bandwidth/data — important for field use in areas with weak signal)
- [ ] Security rules: users can only write their own reports, read rules per your study's access needs
- [ ] (Optional, future work per your paper) admin/LGU-facing view — explicitly out of scope for this thesis build, just don't design yourself into a corner

### Milestone 9 — Testing & Evaluation Support
- [ ] Build in a simple export (CSV/JSON) of local TP/TN/FP/FN classification results + GPS mapping accuracy data, so you can feed Chapter III's confusion matrix and accuracy equations directly from app data
- [ ] QA pass: full offline run-through (Airplane Mode) of capture → classify → GPS tag → map → points → then re-enable internet and confirm sync completes correctly with no data loss or duplication

---

## 4. Non-Negotiable Offline-First Rules (keep pinned in Cursor context)

1. No screen or feature may show a loading spinner waiting on network for anything the user has already generated locally (their own reports, points, map markers).
2. All writes: **local DB first, Firestore second, always via the sync service** — never write to Firestore directly from UI code.
3. The app must be fully demoable in Airplane Mode end-to-end except for the initial map tile download.
4. Every `Report` needs a client-generated UUID before it touches the network, to make sync idempotent.
5. Points/rewards must feel instant to the user — never gate the reward feedback on a network round trip.

---

## 5. Suggested Cursor Workflow

- Feed this file into Cursor as a persistent reference (`@ARID_mobile_cursor_plan.md`) or drop key sections into `.cursor/rules`.
- Work milestone by milestone; don't let Cursor jump ahead to Firebase sync (M7) before offline core (M1–M6) is solid and tested.
- After each milestone, explicitly prompt Cursor: "confirm this works with no internet connection" before moving on.
