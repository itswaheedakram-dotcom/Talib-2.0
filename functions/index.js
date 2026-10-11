const admin = require('firebase-admin');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// A trusted backend can read private bookmarks; client institute screens cannot.
// Deterministic notification IDs make repeated trigger delivery safe.
exports.onInstituteOpportunityCreated = onDocumentCreated('institutes/{instituteId}/opportunities/{opportunityId}', async (event) => {
  const item = event.data?.data();
  if (!item || item.published !== true) return;
  const { instituteId, opportunityId } = event.params;
  const institute = await db.collection('institutes').doc(instituteId).get();
  if (!institute.exists || !['approved', 'verified'].includes(institute.data().status)) return;
  const kind = item.kind === 'scholarship' ? 'scholarship' : item.kind === 'course' ? 'program / course' : 'admission update';
  const text = `New ${kind}: ${item.title} at ${institute.data().name}`;
  const query = db.collectionGroup('instituteBookmarks').where('instituteId', '==', instituteId).limit(400);
  let cursor;
  while (true) {
    const page = await (cursor ? query.startAfter(cursor) : query).get();
    if (page.empty) break;
    const writes = [];
    for (const bookmark of page.docs) {
      const user = bookmark.ref.parent.parent;
      if (!user) continue;
      writes.push(user.collection('notifications').doc(`institute-update-${instituteId}-${opportunityId}`).create({
        type: 'institute_update', text, instituteId, opportunityId,
        fromId: item.createdBy || 'talib-institutes',
        createdAt: event.data.createTime, read: false,
      }).catch((error) => { if (error.code !== 6) throw error; }));
    }
    await Promise.all(writes);
    cursor = page.docs[page.docs.length - 1];
    if (page.size < 400) break;
  }
});

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
  const recipients = new Set();
  const managers = await db.collection('adminRoles').where('role', '==', 'manager_admin').get();
  for (const doc of managers.docs) {
    const role = doc.data();
    if (role.status === 'active' && role.permissions?.manage_reports === true) recipients.add(doc.id);
  }
  const tokenCandidates = await db.collection('pushTokens').where('adminRecipient', '==', true).get();
  for (const doc of tokenCandidates.docs) {
    const user = await admin.auth().getUser(doc.id).catch(() => null);
    if (user?.customClaims?.admin === true) recipients.add(doc.id);
  }
  const admins = await Promise.all([...recipients].map(async (uid) => ({uid, tokenDoc: await db.collection('pushTokens').doc(uid).get()})));
  const batch = db.batch();
  for (const adminRecipient of admins) {
    const notification = db.collection('users').doc(adminRecipient.uid).collection('notifications').doc();
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
  if (admins.length > 0) await batch.commit();
  await sendPush(admins.map((item) => item.tokenDoc).filter((doc) => doc.exists && Array.isArray(doc.data().tokens)), 'New Talib issue: ' + ticketNumber,
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

// Chat alerts go directly to the conversation, never to the bell inbox.
exports.onChatMessageCreated = onDocumentCreated('conversations/{conversationId}/messages/{messageId}', async (event) => {
  const message = event.data?.data();
  if (!message || !message.senderId || !message.receiverId || message.read === true) return;
  const { conversationId, messageId } = event.params;
  const conversation = await db.collection('conversations').doc(conversationId).get();
  if (!conversation.exists) return;
  const chat = conversation.data();
  if (!Array.isArray(chat.participants) || chat.participants.length !== 2 ||
      !chat.participants.includes(message.senderId) || !chat.participants.includes(message.receiverId) ||
      message.senderId === message.receiverId) return;
  const sender = db.collection('users').doc(message.senderId);
  const recipient = db.collection('users').doc(message.receiverId);
  const [following, reverseFollowing, blocked, reverseBlocked, tokenDoc] = await Promise.all([
    sender.collection('following').doc(message.receiverId).get(),
    recipient.collection('following').doc(message.senderId).get(),
    sender.collection('blockedUsers').doc(message.receiverId).get(),
    recipient.collection('blockedUsers').doc(message.senderId).get(),
    db.collection('pushTokens').doc(message.receiverId).get(),
  ]);
  if (!following.exists || !reverseFollowing.exists || blocked.exists || reverseBlocked.exists || !tokenDoc.exists) return;
  const name = chat.participantNames?.[message.senderId] || 'Student';
  await sendPush([tokenDoc], 'New message from ' + name, 'Open Talib to read your message.', {
    type: 'chat_message', conversationId, messageId,
    senderId: message.senderId, receiverId: message.receiverId, senderName: name,
  });
});
