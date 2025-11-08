const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const { onSchedule } = require('firebase-functions/v2/scheduler');

function haversineDistance(lat1, lon1, lat2, lon2) {
  function toRad(x) { return x * Math.PI / 180; }
  const R = 6371e3; // meters
  const φ1 = toRad(lat1);
  const φ2 = toRad(lat2);
  const Δφ = toRad(lat2 - lat1);
  const Δλ = toRad(lon2 - lon1);
  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // in meters
}

exports.notifyOnReportCreate = onDocumentCreated('reports/{reportId}', async (event) => {
  const report = event.data.data();
  const reportId = event.params.reportId;
  if (!report) return;
  const licensePlate = (report.licensePlate || '').toUpperCase().replace(/\s/g, '');
  const lat = report.location?.lat;
  const lng = report.location?.lng;

  const usersSnap = await admin.firestore().collection('users').get();
  const messages = [];

  usersSnap.forEach((doc) => {
    const u = doc.data() || {};
    const token = u.deviceToken;
    if (!token) return;

    let priority = false;
    if ((u.carPlate || '').toUpperCase().replace(/\s/g, '') && licensePlate && (u.carPlate || '').toUpperCase().replace(/\s/g, '') === licensePlate) {
      priority = true;
    }

    let nearby = false;
    if (typeof lat === 'number' && typeof lng === 'number' && typeof u.lastLat === 'number' && typeof u.lastLng === 'number') {
      const d = haversineDistance(lat, lng, u.lastLat, u.lastLng);
      if (d <= 2000) { // 2km radius
        nearby = true;
      }
    }

    if (priority || nearby) {
      messages.push({
        token,
        notification: {
          title: priority ? 'Urgent: Your car may need attention' : 'Nearby car alert',
          body: report.message || 'A car issue was reported nearby.',
        },
        data: {
          reportId,
          lat: String(lat ?? ''),
          lng: String(lng ?? ''),
          licensePlate: licensePlate || '',
          photoUrl: report.photoUrl || '',
          timestamp: report.timestamp || '',
          priority: priority ? '1' : '0',
        },
        android: { priority: priority ? 'high' : 'normal' },
        apns: { headers: { 'apns-priority': priority ? '10' : '5' } },
      });
    }
  });

  logger.info(`Sending ${messages.length} notifications for report ${reportId}`);
  const chunks = [];
  const size = 500;
  for (let i = 0; i < messages.length; i += size) {
    chunks.push(messages.slice(i, i + size));
  }
  for (const batch of chunks) {
    await admin.messaging().sendEach(batch);
  }
});

exports.notifyOnReportResolved = onDocumentUpdated('reports/{reportId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status === 'resolved' || after.status !== 'resolved') return;

  const reporterId = after.reporterId;
  if (!reporterId) return;
  const reporterDoc = await admin.firestore().collection('users').doc(String(reporterId)).get();
  const token = reporterDoc.data()?.deviceToken;
  if (!token) return;

  await admin.messaging().send({
    token,
    notification: {
      title: 'Thanks! The car owner resolved it',
      body: 'Your report was marked as resolved.',
    },
    data: {
      reportId: event.params.reportId,
      status: 'resolved',
    },
  });
});

// Scheduled cleanup: delete resolved reports whose `expireAt` timestamp is
// in the past. Runs every 5 minutes. Requires `expireAt` to be a Firestore
// Timestamp field on the document (see ReportService.markResolved).
exports.cleanupResolvedReports = onSchedule('every 5 minutes', async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  try {
    const q = db.collection('reports')
      .where('status', '==', 'resolved')
      .where('expireAt', '<=', now)
      .limit(1000);
    const snap = await q.get();
    if (snap.empty) {
      logger.info('No resolved reports to cleanup');
      return;
    }
    const docs = snap.docs;
    // Delete in batches of 500
    const chunkSize = 500;
    let deleted = 0;
    for (let i = 0; i < docs.length; i += chunkSize) {
      const chunk = docs.slice(i, i + chunkSize);
      const batch = db.batch();
      chunk.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      deleted += chunk.length;
    }
    logger.info(`Deleted ${deleted} resolved reports`);
  } catch (err) {
    logger.error('Error cleaning up resolved reports', err);
  }
});
