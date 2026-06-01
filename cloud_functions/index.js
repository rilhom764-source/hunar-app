/**
 * Firebase Cloud Functions for Hunar Push Notifications
 * 
 * Deploy instructions:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Init: firebase init functions (select usto1-17806 project)
 * 4. Copy this file to functions/index.js
 * 5. Deploy: firebase deploy --only functions
 * 
 * OR use Firebase Console -> Functions -> Create function
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Trigger: When a new document is created in 'direct_push' collection
 * Action: Send FCM push notification to the target device token
 */
exports.sendDirectPush = functions.firestore
  .document('direct_push/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    if (data.sent) return null;

    const token = data.token;
    const title = data.title || 'Hunar';
    const body = data.body || '';
    const extraData = data.data || {};

    if (!token) {
      await snap.ref.update({ sent: true, error: 'No token' });
      return null;
    }

    try {
      const message = {
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(extraData).map(([k, v]) => [k, String(v)])
        ),
        token: token,
        android: {
          priority: 'high',
          notification: {
            channelId: 'hunar_notifications',
            icon: '@mipmap/ic_launcher',
            color: '#2E7D32',
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      const response = await admin.messaging().send(message);
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmResponse: response,
      });
      console.log(`Push sent: ${title} -> ${token.substring(0, 20)}...`);
    } catch (error) {
      await snap.ref.update({ sent: true, error: error.message });
      console.error(`Push error: ${error.message}`);
    }

    return null;
  });

/**
 * Trigger: When a new document is created in 'pending_notifications' collection
 * Action: Send FCM push notification
 */
exports.sendPendingNotification = functions.firestore
  .document('pending_notifications/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    if (data.sent) return null;

    const token = data.token;
    const title = data.title || 'Hunar';
    const body = data.body || '';
    const extraData = data.data || {};

    // If no token but has targetUserId, look up token
    let targetToken = token;
    if (!targetToken && data.targetUserId) {
      try {
        const tokenDoc = await admin.firestore()
          .collection('fcm_tokens')
          .doc(data.targetUserId)
          .get();
        if (tokenDoc.exists) {
          targetToken = tokenDoc.data().token;
        }
      } catch (e) {
        console.error(`Token lookup error: ${e.message}`);
      }
    }

    if (!targetToken) {
      await snap.ref.update({ sent: true, error: 'No token found' });
      return null;
    }

    try {
      const message = {
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(extraData).map(([k, v]) => [k, String(v)])
        ),
        token: targetToken,
        android: {
          priority: 'high',
          notification: {
            channelId: 'hunar_notifications',
            icon: '@mipmap/ic_launcher',
            color: '#2E7D32',
            sound: 'default',
          },
        },
      };

      const response = await admin.messaging().send(message);
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmResponse: response,
      });
      console.log(`Notification sent: ${title}`);
    } catch (error) {
      await snap.ref.update({ sent: true, error: error.message });
      console.error(`Notification error: ${error.message}`);
    }

    return null;
  });

/**
 * Trigger: When a new document is created in 'push_queue' collection
 * Action: Send FCM to topic or specific user
 */
exports.processPushQueue = functions.firestore
  .document('push_queue/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    if (data.processed) return null;

    const title = data.title || 'Hunar';
    const body = data.body || '';
    const targetTopic = data.targetTopic;
    const targetUserId = data.targetUserId;

    try {
      if (targetTopic) {
        // Send to topic
        const message = {
          notification: { title, body },
          topic: targetTopic,
          android: {
            priority: 'high',
            notification: {
              channelId: 'hunar_notifications',
              sound: 'default',
            },
          },
        };
        await admin.messaging().send(message);
      } else if (targetUserId) {
        // Send to specific user
        const tokenDoc = await admin.firestore()
          .collection('fcm_tokens')
          .doc(targetUserId)
          .get();
        
        if (tokenDoc.exists) {
          const token = tokenDoc.data().token;
          if (token) {
            const message = {
              notification: { title, body },
              token: token,
              android: {
                priority: 'high',
                notification: {
                  channelId: 'hunar_notifications',
                  sound: 'default',
                },
              },
            };
            await admin.messaging().send(message);
          }
        }
      }

      await snap.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      await snap.ref.update({ processed: true, error: error.message });
      console.error(`Queue error: ${error.message}`);
    }

    return null;
  });
