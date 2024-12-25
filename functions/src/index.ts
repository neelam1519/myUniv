import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendGroupMessageNotification = functions.firestore
  .document("rooms/{roomId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();

    if (!messageData) {
      console.error("No message data found");
      return null;
    }

    const senderId = messageData.authorId; // ID of the sender
    const content = messageData.content; // Message content
    const roomId = context.params.roomId;

    // Fetch the sender's name
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    if (!senderDoc.exists) {
      console.error(`Sender with ID ${senderId} not found`);
      return null;
    }

    const senderName = senderDoc.data()?.firstName || "Unknown"; // Fallback if no name found

    // Fetch the room's details to get the list of participants
    const roomDoc = await admin.firestore().collection("rooms").doc(roomId).get();
    const participants = roomDoc.data()?.userIds || []; // Assuming 'userIds' is an array of user IDs

    if (!participants.length) {
      console.error(`No participants found in room: ${roomId}`);
      return null;
    }

    // Exclude the sender from notification recipients
    const recipientIds = participants.filter((id: string) => id !== senderId);

    // Fetch FCM tokens for all recipients
    const tokens: string[] = [];
    for (const userId of recipientIds) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) {
        tokens.push(fcmToken);
      }
    }

    if (!tokens.length) {
      console.error("No FCM tokens found for recipients");
      return null;
    }

    const notification = {
      notification: {
        title: `${senderName} in Group Chat`,
        body: content,
      },
      data: {
        roomId: roomId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await admin.messaging().sendMulticast({
        tokens,
        ...notification,
      });
      console.log("Group notifications sent successfully:", response);
      return null;
    } catch (error) {
      console.error("Error sending group notifications:", error);
      return null;
    }
  });
