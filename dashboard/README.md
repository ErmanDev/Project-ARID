# A.R.I.D. Web Dashboard

LGU / health-worker monitoring view. Reads the same Firestore `reports` and `users` collections the mobile app syncs to. It does not capture, classify, or tag GPS.

## Run

```bash
cd dashboard
cp .env.example .env
# fill .env with the same Firebase project as the mobile app
npm install
npm run dev
```

Open the printed local URL. Sign in with an authorized staff account.

## Staff access

Create a Firestore document `staff/{uid}` for each dashboard user (Console or Admin SDK). Until that exists, sign-in lands on Access denied.

For local bootstrap only, set `VITE_ALLOW_ANY_AUTH=true` in `.env`.

### Viewing the access-denied page

With mock data the signed-in user is staff, so `/denied` redirects to the
dashboard. To work on that page, simulate a non-staff account:

```bash
VITE_MOCK_STAFF=false npm run dev
```

Then open `/denied`. Same for `/login`, which also redirects while a mock staff
session is active.

Enable Email/Password and/or Google in Firebase Auth.

## Deploy

From the repo root, after `cd dashboard && npm run build`:

```bash
firebase deploy --only hosting,firestore:rules
```

Report photos are Cloudinary URLs on each Firestore document. Firebase Storage is not used.

## Browser image analysis

Authorized staff can open **Analyze image** from the monitor header. The page
runs the trained YOLOv5s detector entirely in the browser; selected photos are
not uploaded. The ONNX model is stored at:

`public/models/medsam_yolov5s.onnx`

It detects five potential breeding-container classes: Bottle,
Coconut-Exocarp, Drain-Inlet, Tire, and Vase. A detection indicates a potential
breeding place only and still requires field verification for water, larvae,
or mosquitoes.

Held-out test performance for the included model is 90.4% mAP@50 and 69.0%
mAP@50-95. Training and export steps are recorded in
`../tool/medsam_yolov5_colab.ipynb`.
