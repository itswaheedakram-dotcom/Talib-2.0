const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function backend({ status = 'approved', users = 2 } = {}) {
  const notifications = new Map();
  const bookmarks = Array.from({ length: users }, (_, i) => ({
    index: i,
    ref: { parent: { parent: { collection: () => ({ doc: (id) => ({
      async create(value) {
        const key = `${i}:${id}`;
        if (notifications.has(key)) throw Object.assign(new Error('already exists'), { code: 6 });
        notifications.set(key, { ...value });
      },
    }) }) } } },
  }));
  function query(offset = 0) {
    return {
      where() { return this; }, limit() { return this; },
      startAfter(last) { return query(last.index + 1); },
      async get() {
        const docs = bookmarks.slice(offset, offset + 400);
        return { docs, empty: docs.length === 0, size: docs.length };
      },
    };
  }
  const db = {
    collection: () => ({ doc: () => ({ async get() { return { exists: true, data: () => ({ name: 'Institute', status }) }; } }) }),
    collectionGroup: () => query(),
  };
  const exports = {};
  vm.runInNewContext(fs.readFileSync(require.resolve('./index.js'), 'utf8'), {
    exports,
    require(name) {
      if (name === 'firebase-admin') return { initializeApp() {}, firestore: () => db, messaging: () => ({}) };
      if (name === 'firebase-functions/v2/firestore') return { onDocumentCreated: (_, handler) => handler, onDocumentUpdated: (_, handler) => handler };
      throw new Error(name);
    },
  });
  return { send: exports.onInstituteOpportunityCreated, notifications };
}
const event = {
  params: { instituteId: 'institute-1', opportunityId: 'opportunity-1' },
  data: { data: () => ({ published: true, kind: 'admission', title: 'Fall admissions', createdBy: 'owner' }), createTime: 'created-at' },
};

test('opportunity notification delivery paginates and preserves read state on retries', async () => {
  const { send, notifications } = backend({ users: 401 });
  await send(event);
  assert.equal(notifications.size, 401);
  const first = notifications.values().next().value;
  assert.equal(first.fromId, 'owner');
  assert.equal(first.instituteId, 'institute-1');
  first.read = true;
  await send(event);
  assert.equal(notifications.size, 401);
  assert.equal(first.read, true);
});

test('pending institutes and unpublished opportunities do not notify subscribers', async () => {
  const pending = backend({ status: 'pending' });
  await pending.send(event);
  assert.equal(pending.notifications.size, 0);
  const approved = backend();
  await approved.send({ ...event, data: { data: () => ({ published: false }) } });
  assert.equal(approved.notifications.size, 0);
});
