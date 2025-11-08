/**
 * add_report.js
 *
 * Usage:
 *   node scripts/add_report.js --reporterId uid123 --lat 1.23 --lng 4.56 \
 *     --licensePlate ABC123 --message "Test alert" --anonymous=false
 *
 * This script initializes the Firebase Admin SDK (using default credentials)
 * and writes a report document to the `reports` collection. It is intended
 * for creating test data locally or in a project where you have admin
 * credentials configured (e.g., via GOOGLE_APPLICATION_CREDENTIALS).
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize the admin SDK. If running inside functions directory (and you
// previously called admin.initializeApp() in index.js), this will be a no-op
// but calling initializeApp() here is safe when running the script locally.
try {
  admin.initializeApp();
} catch (e) {
  // ignore if already initialized
}

const db = admin.firestore();

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const val = args[i + 1];
    if (!val || val.startsWith('--')) {
      out[key] = 'true';
      continue;
    }
    out[key] = val;
    i++;
  }
  return out;
}

function normalizePlate(s) {
  if (!s) return null;
  return String(s).toUpperCase().replace(/\s+/g, '');
}

async function main() {
  const argv = parseArgs();

  const reporterId = argv.reporterId || argv.uid || 'test-user';
  const lat = parseFloat(argv.lat ?? argv.latitude ?? '0') || 0;
  const lng = parseFloat(argv.lng ?? argv.longitude ?? '0') || 0;
  const licensePlate = normalizePlate(argv.licensePlate || argv.plate || '');
  const message = argv.message || '';
  const anonymous = (argv.anonymous === 'true') || false;
  const photoUrl = argv.photoUrl || null;

  const now = new Date();
  const data = {
    reporterId,
    photoUrl,
    location: { lat, lng },
    licensePlate: licensePlate || null,
    message: message || null,
    status: 'open',
    timestamp: now.toISOString(),
    anonymous: !!anonymous,
  };

  console.log('Writing report with data:', data);
  const ref = await db.collection('reports').add(data);
  console.log('Created report:', ref.id);
  process.exit(0);
}

main().catch((err) => {
  console.error('Error creating report:', err);
  process.exit(1);
});
