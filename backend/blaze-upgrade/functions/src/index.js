/**
 * Shareloop – Cloud Messaging base (Phase 1, Infra / Dulum)
 *
 * Triggers:
 *  - onRequestCreated : notify donor when someone requests their item
 *  - onRequestUpdated : notify requester when donor accepts / rejects
 * Every push is also stored in `notifications/` for the in-app list,
 * and dead FCM tokens are removed from users/{uid}.fcmTokens.
 */
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const { FieldValue } = admin.firestore;

// Same region as Firestore (asia-south1, Mumbai)
setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

const DEAD_TOKEN_ERRORS = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

/** Store an in-app notification and push it to all of the user's devices. */
async function notifyUser(userId, { type, title, body, data = {} }) {
  if (!userId) return;

  await db.collection("notifications").add({
    userId, type, title, body, data,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  const userSnap = await db.collection("users").doc(userId).get();
  const tokens = (userSnap.get("fcmTokens") || []).filter(Boolean);
  if (tokens.length === 0) return;

  // FCM data payload values must be strings
  const strData = Object.fromEntries(
    Object.entries({ ...data, type }).map(([k, v]) => [k, String(v)])
  );

  const res = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: strData,
    android: { priority: "high", notification: { channelId: "shareloop_default" } },
  });

  const dead = [];
  res.responses.forEach((r, i) => {
    if (!r.success && DEAD_TOKEN_ERRORS.has(r.error?.code)) dead.push(tokens[i]);
  });
  if (dead.length) {
    await userSnap.ref.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
    logger.info(`Removed ${dead.length} dead token(s) for ${userId}`);
  }
}

exports.onRequestCreated = onDocumentCreated("requests/{requestId}", async (event) => {
  const req = event.data?.data();
  if (!req) return;
  const { requestId } = event.params;

  await db.collection("items").doc(req.itemId)
    .update({ requestCount: FieldValue.increment(1) })
    .catch((e) => logger.warn("requestCount update failed", e));

  await notifyUser(req.donorId, {
    type: "new_request",
    title: "New request for your item",
    body: `Someone requested "${req.itemTitle || "your item"}"`,
    data: { requestId, itemId: req.itemId },
  });
});

exports.onRequestUpdated = onDocumentUpdated("requests/{requestId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return;
  const { requestId } = event.params;

  if (after.status === "accepted") {
    await db.collection("items").doc(after.itemId).update({
      status: "reserved", updatedAt: FieldValue.serverTimestamp(),
    });
    await notifyUser(after.requesterId, {
      type: "request_accepted",
      title: "Request accepted 🎉",
      body: `Your request for "${after.itemTitle || "an item"}" was accepted`,
      data: { requestId, itemId: after.itemId },
    });
  } else if (after.status === "rejected") {
    await notifyUser(after.requesterId, {
      type: "request_rejected",
      title: "Request update",
      body: `Your request for "${after.itemTitle || "an item"}" was not accepted`,
      data: { requestId, itemId: after.itemId },
    });
  } else if (after.status === "completed") {
    await db.collection("items").doc(after.itemId).update({
      status: "donated", updatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection("users").doc(after.donorId).update({
      donationCount: FieldValue.increment(1),
    });
  }
});
