# A.R.I.D. Web Dashboard — Cursor Build Plan

**A.R.I.D.** — Autonomous Risk Identification and Distribution Mapping of Dengue Vector Breeding Sites

**Purpose:** A web-based monitoring dashboard, separate from the mobile app, that displays the **live, aggregated map of reports coming in from the mobile app** for a given area (barangay/city). This is the LGU/health-worker-facing view mentioned in your Significance of the Study — it consumes data the mobile app already produces; it does not do any capture, classification, or GPS tagging itself.

This is **read/monitor-first, not offline-first** — unlike the mobile app, this dashboard's whole job is to show current, synced data, so it expects an internet connection. Keep it visually and structurally consistent with the mobile app (same color theme, same data model) since they share one Firebase backend.

---

## 0. Relationship to the Mobile App

- Mobile app = data producer (offline-first, writes `Report` records, syncs to Firestore when online)
- Web dashboard = data consumer (reads from the same Firestore `reports` collection, near-real-time)
- **No duplicate logic.** The dashboard never re-runs AI classification or re-computes risk levels — it only displays what the mobile app + sync service already determined.
- Same Firebase project, same `Report` schema as defined in the mobile plan — don't diverge the data model between the two apps.

---

## 1. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | React (Vite) or Next.js | Next.js if you want server-rendering/auth routes later; Vite+React is lighter if it's just an internal dashboard |
| Map | Leaflet (`react-leaflet`) | Matches the Leaflet tool already named in your Chapter I conceptual framework, keeps thesis consistency |
| Backend/data | Firebase (Firestore + Storage) — same project as mobile | Real-time listeners (`onSnapshot`) for live updates, not polling |
| Auth | Firebase Auth | Gate the dashboard behind login — this is an LGU/health-worker tool, not public |
| State | React Query or simple Context, kept light | Dashboard is mostly "subscribe and render," doesn't need heavy state management |
| Styling | Tailwind CSS | Fast to keep consistent with the theme tokens below |
| Hosting | Firebase Hosting | Keeps everything in one Firebase project, simplest deploy path |

---

## 2. Theme / Color Palette (shared with mobile app)

Reuse the exact palette from the mobile app plan so both surfaces feel like one product.

| Role | Hex | Notes |
|---|---|---|
| Primary (brand) | `#4A7A8C` muted teal-blue | Nav bar, primary buttons, active states |
| Secondary (brand) | `#6B9080` muted sage green | Secondary buttons, accents |
| High Risk (Red) | `#B5555A` muted brick red | Marker color + risk badges only |
| Moderate Risk (Yellow) | `#C9A66B` muted amber | Marker color + risk badges only |
| Low Risk / Safe (Green) | `#7C9C7C` muted sage green | Marker color + risk badges only |
| Background | `#F5F5F3` off-white | App background |
| Surface / Cards | `#FFFFFF` | Panels, cards, modals |
| Text primary | `#2E3438` dark slate | Headings, body |
| Text secondary | `#6E7477` grey | Metadata, timestamps, labels |
| Border / Divider | `#E2E2E0` light grey | Table borders, dividers |

Same rule as mobile: risk colors are reserved for risk indicators only (map markers, status badges, area heat levels) — never reused for generic buttons or nav elements. Flat fills, no gradients, define as design tokens (`tailwind.config` theme extension) once, use everywhere.

---

## 3. Data Model (read-only consumer of mobile's schema)

```
Report {          // read-only here — written only by mobile app's sync service
  id
  imageRemoteUrl
  classification: breeding | nonBreeding
  confidenceScore
  riskLevel: red | yellow | green
  latitude, longitude, gpsAccuracy
  capturedAt
  userId
  pointsAwarded
  syncStatus       // dashboard should only display syncStatus == synced
}

UserProfile {      // read-only here
  id, displayName, totalPoints, reportCount
}
```

- Dashboard queries Firestore directly (with Firestore security rules restricting write access to server/mobile sync only).
- Only display records with `syncStatus == 'synced'` so the dashboard never shows a report before it's confirmed in the cloud.

---

## 4. Milestones

### Milestone 1 — Project Scaffold & Auth
- [ ] React/Next.js project init, Tailwind setup, theme tokens from Section 2
- [ ] Firebase Auth login screen (email/password or Google sign-in — scope to authorized health workers/LGU staff)
- [ ] Protected route wrapper — dashboard content only renders when authenticated
- [ ] Basic layout shell: top nav, sidebar (optional), main map/content area

### Milestone 2 — Live Area Map (core feature)
This is the heart of the site: **monitor the current area on the map, live.**

- [ ] `react-leaflet` map centered on the study area (default center/zoom configurable)
- [ ] Firestore `onSnapshot` real-time listener on `reports` collection (filtered to `syncStatus == synced`, and optionally by date range)
- [ ] Render each report as a color-coded marker (red/yellow/green per `riskLevel`) — same color meaning as mobile app
- [ ] Marker click → popup/side panel with report detail: image, classification, confidence, timestamp, reporter (if not anonymized)
- [ ] Auto-update markers as new synced reports stream in — no manual refresh needed
- [ ] Visual "last updated" indicator so viewers know the data is live, not stale

### Milestone 3 — Area Filtering & Boundaries
- [ ] Define monitored area(s) — either a fixed bounding box/polygon for your study area, or barangay-level boundaries if you have GeoJSON for them
- [ ] Restrict map view/query to the current monitored area by default (pan/zoom out reveals more if needed, but default view = the area being monitored)
- [ ] Optional: dropdown to switch between multiple monitored areas/barangays if the study eventually covers more than one
- [ ] Filter controls: risk level (show/hide red/yellow/green), date range, classification type

### Milestone 4 — Hotspot / Density View
- [ ] Toggle between marker view and a heatmap/density view (`leaflet.heat` or clustering via `react-leaflet-cluster`) to surface **recurring breeding hotspots**, directly supporting the "documenting reported locations and generating historical records of recurring breeding hotspots" point from your Significance of the Study
- [ ] Highlight areas with repeated red-risk reports over time (simple count-based aggregation is enough — no need for complex spatial statistics for a thesis-scope tool)

### Milestone 5 — Summary Panel / Stats
- [ ] At-a-glance counters: total reports, breakdown by risk level, reports in last 24h/7d
- [ ] Simple trend indicator (e.g., reports this week vs last week) — supports LGUs prioritizing inspections
- [ ] Top contributors / leaderboard view pulling `UserProfile.totalPoints` — ties into the mobile app's rewards system, gives LGUs visibility into active community reporters

### Milestone 6 — Report Detail & Status
- [ ] Dedicated report detail view/modal: full-size image, GPS coordinates, confidence score, risk level, timestamp, sync status
- [ ] (Optional, if in scope) manual verification action for staff — mark a report reviewed/actioned, stored back to Firestore as a separate `reviewStatus` field so it doesn't interfere with mobile's own `syncStatus`/`pointsAwarded` logic

### Milestone 7 — Responsiveness & Field Use
- [ ] Dashboard should be usable on tablet as well as desktop (health workers may check it in the field)
- [ ] Graceful "offline" state message if connection drops — this app is online-first, so just show a clear "reconnecting..." banner rather than pretending to work offline

### Milestone 8 — Deployment
- [ ] Firebase Hosting deploy
- [ ] Firestore security rules finalized: dashboard role = read-only on `reports`/`users`, write access limited to the optional `reviewStatus` field from Milestone 6
- [ ] Basic access control review — confirm only authorized accounts can log in

---

## 5. Non-Negotiable Rules

1. This site **never writes** classification, GPS, or risk-level data — that's the mobile app's job. The dashboard only reads, plus optionally writes a lightweight `reviewStatus` if you choose to build Milestone 6's verification action.
2. Only show `synced` reports — never partially-synced or local-only data, since this dashboard has no concept of "local."
3. Real-time via Firestore listeners, not manual refresh buttons, so "monitor the current area" actually means live monitoring.
4. Same color system as mobile — don't let the two surfaces drift into different visual languages.
5. Keep this explicitly scoped as a monitoring tool for the study/LGU use case — resist scope creep into a second full app; it's a lightweight complement to the mobile app, not a rebuild of it.

---

## 6. Suggested Cursor Workflow

- Reference both this file and `ARID_mobile_cursor_plan.md` together in Cursor context so the shared data model and theme stay in sync across the two codebases.
- Build Milestone 1–2 first (auth + live map) since that's the core "monitor the current area" requirement — everything else layers on top.
- Since this app assumes connectivity, testing is simpler than mobile: just verify the Firestore listener updates the map in real time when a new report syncs from the mobile app.
