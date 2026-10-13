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

Everyone signs in with a **username and password**. Behind the scenes each
username is a Firebase Auth email/password account at `<username>@arid.local`
(no mail is sent there). The account's details, role, and status live in
Firestore `users/{uid}`.

- **Admins** use this dashboard. There is no registration here: admins are
  created only with `tool/create_admin.js`.
- **Staff** register on the mobile app with their first, middle (optional),
  and last name, birthday (15 or older), username, and password. They start
  **Pending** and cannot sign in until an admin verifies them in the
  **User Verification** tab.

In User Verification an admin can **Verify** or **Reject** a pending request,
**Revoke** a verified account (it becomes Rejected), and **Delete** a rejected
request. Someone whose request was deleted can register again with the same
username and password. `firebase/firestore.rules` enforces all of this, so it
cannot be bypassed through the API.

Create another admin, or recover access if none is left, from the repo root
after `firebase login`:

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
