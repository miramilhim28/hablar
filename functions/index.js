const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;

    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    const participants = chatDoc.data().participants;
    const senderId = message.senderId;

    // Fetch sender name
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.data().name || "Someone";

    const recipients = participants.filter(uid => uid !== senderId);

    for (const userId of recipients) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const token = userDoc.data().fcmToken;

      if (token) {
        await admin.messaging().send({
          token,
          notification: {
            title: `${senderName}`,
            body: message.text,
          },
          data: {
            chatId,
            senderId,
          },
        });
      }
    }
  });

