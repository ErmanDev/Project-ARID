/**
 * Creates a verified admin account for the web dashboard.
 *
 * Usage (from the repo root, after `firebase login`):
 *   node tool/create_admin.js <username> "<Display name>" [password]
 *
 * Without a password, a random one is generated and printed once. Use this to
 * create the first admin, or to recover access if no verified admin is left.
 * Everyone else registers in the app or dashboard and is verified from the
 * dashboard's Users tab.
 */
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');

const project = 'arid-dengue-mapping';
// Must match the mobile app (AuthService.usernameDomain) and the dashboard
// (USERNAME_DOMAIN) so the account signs in with just the username.
const usernameDomain = 'arid.local';

const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const token = JSON.parse(fs.readFileSync(cfgPath, 'utf8')).tokens.access_token;

function randomPassword() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  const bytes = crypto.randomBytes(16);
  return Array.from(bytes, (byte) => alphabet[byte % alphabet.length]).join('');
}

async function call(url, method, body) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'x-goog-user-project': project,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (res.status < 200 || res.status >= 300) {
    throw new Error(`${method} ${url} failed (${res.status}): ${text}`);
  }
  return JSON.parse(text || '{}');
}

async function main() {
  const [rawUsername, displayName, givenPassword] = process.argv.slice(2);
  if (!rawUsername || !displayName) {
    console.error('Usage: node tool/create_admin.js <username> "<Display name>" [password]');
    process.exit(1);
  }
  const username = rawUsername.trim().toLowerCase();
  if (!/^[a-z0-9][a-z0-9._-]{2,29}$/.test(username)) {
    throw new Error('Username must be 3-30 letters, numbers, dots, dashes, or underscores.');
  }
  const password = givenPassword ?? randomPassword();
  if (password.length < 6) throw new Error('Password must be at least 6 characters.');

  const account = await call(
    `https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts`,
    'POST',
    { email: `${username}@${usernameDomain}`, password, displayName, emailVerified: true },
  );
  const uid = account.localId;
  const now = new Date().toISOString();

  await call(
    `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/users/${uid}`,
    'PATCH',
    {
      fields: {
        username: { stringValue: username },
        displayName: { stringValue: displayName },
        role: { stringValue: 'admin' },
        verified: { booleanValue: true },
        createdAt: { timestampValue: now },
        verifiedAt: { timestampValue: now },
        verifiedBy: { stringValue: 'tool/create_admin.js' },
        updatedAt: { timestampValue: now },
        totalPoints: { integerValue: '0' },
        verifiedPoints: { integerValue: '0' },
        reportCount: { integerValue: '0' },
      },
    },
  );

  console.log(`Created verified admin @${username} (uid ${uid})`);
  if (!givenPassword) console.log(`Password: ${password}`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
