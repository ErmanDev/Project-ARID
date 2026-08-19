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

Enable Email/Password and/or Google in Firebase Auth.

## Deploy

From the repo root, after `cd dashboard && npm run build`:

```bash
firebase deploy --only hosting,firestore:rules
```

Report photos are Cloudinary URLs on each Firestore document. Firebase Storage is not used.
