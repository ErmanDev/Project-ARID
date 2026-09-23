/**
 * Creates staff/{uid} documents so the dashboard can read Firestore reports.
 * Usage: node tool/add_staff.js <uid> [email] [displayName]
 * Or with no args: provisions known Google accounts from auth export.
 */
const fs = require('fs');
const path = require('path');
const os = require('os');

const project = 'arid-dengue-mapping';
const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const token = JSON.parse(fs.readFileSync(cfgPath, 'utf8')).tokens.access_token;

const DEFAULT_STAFF = [
  {
    uid: '07zScoXJVZPt0do37kBL2xgBmZh1',
    email: 'aieshakaching@gmail.com',
    displayName: 'Aiesha',
  },
  {
    uid: 'BO7KwRHgrBYmOJK4aFPzZiZMg4q1',
    email: 'ermanfaminiano020@gmail.com',
    displayName: 'Erman Louie Faminiano',
  },
  {
    uid: 'IsA0snzEOmZ7PguLp3CtjBgTUm23',
    email: 'koresensi.299@gmail.com',
    displayName: 'Erman Faminiano',
  },
];

async function upsertStaff({ uid, email, displayName }) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${project}` +
    `/databases/(default)/documents/staff/${uid}`;
  const body = {
    fields: {
      email: { stringValue: email },
      displayName: { stringValue: displayName },
      role: { stringValue: 'staff' },
      createdAt: { stringValue: new Date().toISOString() },
    },
  };
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (res.status < 200 || res.status >= 300) {
    throw new Error(`staff/${uid} failed (${res.status}): ${text}`);
  }
  console.log(`staff/${uid} ok (${email})`);
}

async function main() {
  const args = process.argv.slice(2);
  const rows =
    args.length >= 1
      ? [
          {
            uid: args[0],
            email: args[1] ?? '',
            displayName: args[2] ?? 'Staff',
          },
        ]
      : DEFAULT_STAFF;

  for (const row of rows) {
    await upsertStaff(row);
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
