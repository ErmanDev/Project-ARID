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

Open the printed local URL and sign in with an admin username and password.

## Accounts

Everyone signs in with a **username and password**, on the web and on the
mobile app. Behind the scenes each username is a Firebase Auth email/password
account at `<username>@arid.local` (no mail is sent there). The account's role
and status live in Firestore `users/{uid}`:

| Where you register | Role | Status | Can sign in to |
|---|---|---|---|
| Mobile app | `field` (field reporter) | Verified at once | Mobile app |
| This dashboard | `admin` | Pending | Nothing until an admin clicks **Verify** in the **Users** tab |

Only verified admins can use the dashboard. The **Users** tab lists every
account, shows who is waiting, and lets an admin verify or revoke anyone but
themselves. `firebase/firestore.rules` enforces all of this, so nobody can
register as a verified admin or verify themselves through the API.

If no verified admin is left, create one from the repo root after
`firebase login`:

```bash
node tool/create_admin.js <username> "<Display name>" [password]
```

### Viewing the access page

`/denied` is shown when a signed-in account loses access mid-session (an admin
revoked it). With mock data, simulate that with:

```bash
VITE_MOCK_STAFF=false npm run dev
```

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
