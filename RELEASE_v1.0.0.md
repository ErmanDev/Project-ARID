# A.R.I.D. v1.0.0 — First Field Release

**Autonomous Risk Identification and Distribution Mapping of Dengue Vector Breeding Sites**

First production-ready release of the offline-first mobile app and LGU monitoring dashboard.

## Mobile app (v1.0.0+1)

### Capture workflow

- Take or pick a photo → on-device TFLite classification
- Review remarks (label, confidence, risk level)
- Confirm → pin current location → save locally
- Auto-sync to cloud when online (Firestore + Cloudinary)

### Risk & map colors

- **Red** — high-confidence breeding site
- **Yellow** — lower-confidence breeding site
- **Blue** — non-breeding site

### Offline-first

- Full capture, classify, GPS, map, history, and points work without internet
- Background sync when connectivity returns
- Offline map tile download for field use

### Install

- Download `app-release.apk` from this release
- Android 7.0+ (API 24+)
- Enable install from unknown sources if prompted

---

## Web dashboard (v1.0.0)

**Live monitoring:** https://arid-dengue-mapping.web.app

- Live Firestore map with risk-colored pins
- Photo viewer, confidence, GPS accuracy
- Staff review status (Unreviewed / Reviewed / Actioned)
- Filters: location scope, risk, classification, date, layers
- **All locations** scope for reports outside Metro Manila
- Browser-based image analysis (YOLO + classifier) for staff

Staff sign-in via Google. Requires a `staff/{uid}` Firestore document.

---

## Cloud stack (free tier)

| Service | Role |
|--------|------|
| **Firebase Auth** | Anonymous (mobile), Google/email (dashboard) |
| **Firestore** | Report metadata sync |
| **Cloudinary** | Report photo hosting |
| **Firebase Hosting** | Dashboard deployment |

---

## What's included in this release

- Confirm-before-pin capture flow (breeding and non-breeding)
- Blue pin color for non-breeding sites (mobile + dashboard)
- Mock data disabled — live Firestore data only
- Firestore security rules deployed
- On-device model support (`arid_model.tflite`)
- Dashboard default scope set to **All locations** (Philippines)

---

## Known limitations

- APK is signed with a **debug key** — suitable for field testing, not Play Store
- Dashboard `VITE_ALLOW_ANY_AUTH=true` may still be enabled for bootstrap; set to `false` and use `staff/{uid}` docs for production access control
- Study-area presets (Metro Manila, Quezon City, Manila) remain available as filters

---

## Test plan

- [ ] Install APK, capture a report, confirm & pin
- [ ] Profile → Sync now (online)
- [ ] Dashboard → sign in → pin appears on map (Scope: All locations)
- [ ] Click pin → photo loads, review status can be updated
- [ ] Verify offline capture still works in airplane mode

---

**Tag:** `v1.0.0`  
**Mobile:** `1.0.0+1` · **Dashboard:** `1.0.0`
