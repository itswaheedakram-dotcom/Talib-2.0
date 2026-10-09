const admin = require('firebase-admin');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

async function sendPush(tokenDocs, title, body, data) {
  const tokens = [];
  for (const doc of tokenDocs) {
    const list = Array.isArray(doc.data().tokens) ? doc.data().tokens : [];
    for (const token of list) if (typeof token === 'string' && token.length > 0) tokens.push(token);
  }
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    if (!chunk.length) continue;
    await messaging.sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v ?? '')])),
      android: { priority: 'high', notification: { channelId: 'talib_support' } },
    });
  }
}

exports.onIssueTicketCreated = onDocumentCreated('issueTickets/{ticketId}', async (event) => {
  const ticket = event.data?.data();
  if (!ticket || !ticket.reporterId) return;
  const ticketId = event.params.ticketId;
  const ticketNumber = ticket.ticketNumber || ticketId;
  const candidates = await db.collection('pushTokens').where('adminRecipient', '==', true).get();
  const eligible = await Promise.all(candidates.docs.map(async (doc) => {
    const role = await db.collection('adminRoles').doc(doc.id).get();
    const user = await admin.auth().getUser(doc.id).catch(() => null);
    const customAdmin = user?.customClaims?.admin === true;
    const data = role.data() || {};
    const managerAllowed = data.role === 'manager_admin' && data.status === 'active' && data.permissions?.manage_reports === true;
    return customAdmin || managerAllowed ? doc : null;
  }));
  const admins = eligible.filter(Boolean);
  const batch = db.batch();
  for (const doc of admins) {
    const notification = db.collection('users').doc(doc.id).collection('notifications').doc();
    batch.set(notification, {
      type: 'issue_created',
      text: 'New issue report: ' + (ticket.title || ticketNumber),
      fromId: 'talib-support',
      ticketId,
      ticketNumber,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });
  }
  if (!admins.empty) await batch.commit();
  await sendPush(admins.docs, 'New Talib issue: ' + ticketNumber,
    (ticket.category || 'Support') + ': ' + (ticket.title || 'New issue report'),
    { type: 'issue_created', ticketId, ticketNumber });
});

exports.onIssueTicketUpdated = onDocumentUpdated('issueTickets/{ticketId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || !after.reporterId) return;
  const statusChanged = before.status !== after.status;
  const replyChanged = (before.latestReply || '') !== (after.latestReply || '');
  if (!statusChanged && !replyChanged) return;
  const ticketId = event.params.ticketId;
  const ticketNumber = after.ticketNumber || ticketId;
  const parts = [];
  if (statusChanged) parts.push('Status: ' + after.status);
  if (replyChanged && after.latestReply) parts.push('Support replied: ' + after.latestReply);
  const text = parts.join(' • ') || 'Your support ticket was updated.';
  await db.collection('users').doc(after.reporterId).collection('notifications').add({
    type: 'issue_update',
    text,
    fromId: 'talib-support',
    ticketId,
    ticketNumber,
    status: after.status || 'open',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });
  const tokenDoc = await db.collection('pushTokens').doc(after.reporterId).get();
  if (tokenDoc.exists) await sendPush([tokenDoc], 'Talib support update: ' + ticketNumber, text,
    { type: 'issue_update', ticketId, ticketNumber, status: after.status || 'open' });
});
