# A.R.I.D.

Autonomous Risk Identification and Distribution Mapping of Dengue Vector Breeding Sites.

Offline-first Flutter app: capture, on-device classification, GPS tagging, map, history, and points all work with Airplane Mode on. Firebase is a background sync target only.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Teachable Machine model

Export TFLite from Teachable Machine and place it at:

`assets/models/arid_model.tflite`

Update `assets/models/labels.txt` to match your class names. Until that file exists, a deterministic on-device fallback still produces local reports so the rest of the pipeline can be tested offline.

## Firebase + Cloudinary (free)

1. Create a Firebase project on the Spark/free plan (Auth + Firestore only — **not** Storage).
2. Run `flutterfire configure`.
3. Deploy rules from `firebase/firestore.rules`.
4. Create a [free Cloudinary](https://cloudinary.com/users/register/free) account (no credit card).
5. In Cloudinary: **Settings → Upload → Upload presets → Add upload preset**.
   - Signing mode: **Unsigned**
   - Folder (optional): `arid-reports`
   - Name it `arid_unsigned`
6. In the app **Profile** screen, paste your Cloudinary **cloud name** and preset, then Sync.

Photos stay on-device until sync. The dashboard shows the Cloudinary URL stored on each Firestore report.

The app remains fully usable if cloud services are not configured; reports stay in the local queue.

## Offline map tiles

Open Map, pan to the study area while online, then tap download. Cached tiles remain available in Airplane Mode. Browse-as-you-go also caches tiles automatically.

## Points

Provisional points are awarded on-device at submission. They become verified after a successful sync. Thresholds and point values live in the local `AppConfig` table.

## Web dashboard

LGU monitoring UI lives in `dashboard/`. See `dashboard/README.md`. It reads the same Firestore project; it never captures or classifies.

```bash
cd dashboard
npm install
npm run dev
```

## Evaluation export

On Profile, label ground truth from History, then export CSV/JSON for Chapter III confusion-matrix calculations.
