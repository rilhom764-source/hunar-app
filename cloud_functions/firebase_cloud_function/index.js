/**
 * Firebase Cloud Function: Auto-send push notifications
 * 
 * Triggers when a new document is created in 'pending_notifications' collection.
 * Reads FCM token and sends push via Firebase Admin SDK.
 * 
 * DEPLOYMENT:
 *   cd cloud_functions/firebase_cloud_function
 *   firebase deploy --only functions
 * 
 * OR deploy via Firebase Console:
 *   1. Go to Firebase Console -> Functions
 *   2. Create a new function
 *   3. Set trigger: Firestore -> Document created -> pending_notifications/{docId}
 *   4. Paste this code
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Trigger: new document in pending_notifications
 * Sends FCM push to the target user
 */
exports.sendPushNotification = onDocumentCreated(
  "pending_notifications/{docId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const db = getFirestore();
    const docRef = event.data.ref;

    let token = data.token || "";
    const title = data.title || "Hunar";
    const body = data.body || "";
    const extraData = data.data || {};
    const targetUserId = data.targetUserId || "";

    // If no token, try to look up by targetUserId
    if (!token && targetUserId) {
      try {
        const tokenDoc = await db.collection("fcm_tokens").doc(targetUserId).get();
        if (tokenDoc.exists) {
          token = tokenDoc.data()?.token || "";
        }
      } catch (e) {
        console.error("Token lookup error:", e);
      }
    }

    if (!token) {
      await docRef.update({ sent: true, error: "No FCM token found" });
      return;
    }

    try {
      const message = {
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(extraData).map(([k, v]) => [String(k), String(v)])
        ),
        token,
        android: {
          priority: "high",
          notification: {
            channelId: "hunar_notifications",
            icon: "@mipmap/ic_launcher",
            color: "#2E7D32",
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
      };

      const response = await getMessaging().send(message);
      await docRef.update({
        sent: true,
        sentAt: new Date(),
        fcmResponse: response,
      });
      console.log(`SENT: [${data.type}] ${title} -> user:${targetUserId}`);
    } catch (error) {
      await docRef.update({
        sent: true,
        error: error.message?.substring(0, 500) || "Unknown error",
      });

      // Clean up expired token
      if (
        error.code === "messaging/registration-token-not-registered" &&
        targetUserId
      ) {
        try {
          await db.collection("fcm_tokens").doc(targetUserId).delete();
          console.log(`Cleaned expired token for user ${targetUserId}`);
        } catch (e) {
          console.error("Token cleanup error:", e);
        }
      }

      console.error(`ERROR: ${error.message}`);
    }
  }
);

/**
 * Trigger: new document in push_queue (topic-based)
 * Sends FCM push to a topic
 */
exports.sendTopicPush = onDocumentCreated(
  "push_queue/{docId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const docRef = event.data.ref;
    const title = data.title || "";
    const body = data.body || "";
    const targetTopic = data.targetTopic || "";
    const extraData = data.data || {};

    if (!targetTopic) {
      await docRef.update({ processed: true, error: "No target topic" });
      return;
    }

    try {
      const message = {
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(extraData).map(([k, v]) => [String(k), String(v)])
        ),
        topic: targetTopic,
        android: {
          priority: "high",
          notification: {
            channelId: "hunar_notifications",
            sound: "default",
          },
        },
      };

      const response = await getMessaging().send(message);
      await docRef.update({
        processed: true,
        processedAt: new Date(),
        fcmResponse: response,
      });
      console.log(`TOPIC [${targetTopic}]: ${title}`);
    } catch (error) {
      await docRef.update({
        processed: true,
        error: error.message?.substring(0, 500) || "Unknown error",
      });
      console.error(`TOPIC ERROR: ${error.message}`);
    }
  }
);
