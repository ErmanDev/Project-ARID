const fs = require('fs');
const path = require('path');
const os = require('os');

const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const token = cfg.tokens.access_token;
const project = 'arid-dengue-mapping';

async function api(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json };
}

async function main() {
  const services = [
    'firestore.googleapis.com',
    'identitytoolkit.googleapis.com',
    'firebase.googleapis.com',
  ];
  for (const service of services) {
    const result = await api(
      'POST',
      `https://serviceusage.googleapis.com/v1/projects/${project}/services/${service}:enable`,
    );
    console.log(`enable ${service}: ${result.status}`);
  }

  const db = await api(
    'POST',
    `https://firestore.googleapis.com/v1/projects/${project}/databases?databaseId=(default)`,
    {
      locationId: 'asia-southeast1',
      type: 'FIRESTORE_NATIVE',
    },
  );
  console.log(`create firestore: ${db.status} ${JSON.stringify(db.json.error || db.json.name || db.json)}`);

  const authGet = await api(
    'GET',
    `https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config`,
  );
  console.log(`get auth config: ${authGet.status}`);

  const authPatch = await api(
    'PATCH',
    `https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config?updateMask=signIn.anonymous,signIn.email`,
    {
      signIn: {
        anonymous: { enabled: true },
        email: { enabled: true, passwordRequired: true },
      },
    },
  );
  console.log(`patch auth: ${authPatch.status} ${JSON.stringify(authPatch.json.error || { ok: true })}`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
