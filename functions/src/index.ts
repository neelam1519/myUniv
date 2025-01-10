import * as functions from "firebase-functions/v2"; // Import from v2
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendGroupMessageNotification = functions.firestore
  .onDocumentCreated("rooms/{roomId}/messages/{messageId}", async (event) => {
    const snapshot = event.data; // Get the snapshot from the event

    // Check if snapshot is defined
    if (!snapshot) {
      console.error("Snapshot is undefined");
      return null;
    }

    const messageData = snapshot.data();
    console.log('Message Data:', messageData);

    if (!messageData) {
      console.error("No message data found");
      return null;
    }

    const senderId = messageData.authorId;
    const message = messageData.text;
    const roomId = event.params.roomId;

    console.log('Function triggered for room:', roomId);

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

    // Exclude the sender from the participants
    //const recipientIds = participants.filter((id: string) => id !== senderId);
    // Fetch FCM tokens for all recipients

    console.log('recipientIds: ', participants);
    const tokens: string[] = [];
    for (const userId of participants) {
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
    body: message,
  },
  data: {
    roomId: roomId,
    route: "/home",
    click_action: "FLUTTER_NOTIFICATION_CLICK", // Required for Android deep linking
  },
  android: {
    notification: {
      clickAction: "FLUTTER_NOTIFICATION_CLICK", // For handling notifications in Flutter
      channelId: "Neelam", // Ensure this matches the app's notification channel
      sound: "default", // Play the default notification sound
    },
  },
};



    try {
      const response = await admin.messaging().sendEachForMulticast({ tokens, ...notification });
      console.log("Group notifications sent successfully:", response);
       if (response.responses) {
                  response.responses.forEach((resp, index) => {
                      if (!resp.success) {
                          console.error(`Failed to send notification to token ${tokens[index]}: ${resp.error?.message || 'Unknown error'}`);
                      }
                  });
              }
      return null;
    } catch (error) {
      console.error("Error sending group notifications:", error);
      return null;
    }
  });