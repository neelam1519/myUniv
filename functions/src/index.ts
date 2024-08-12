import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const getUidByEmail = functions.https.onRequest(
  async (request, response) => {
    const email = request.query.email as string;

    if (!email) {
      response.status(400).send("Email is required");
      return;
    }

    try {
      // Get the user by email
      const userRecord = await admin.auth().getUserByEmail(email);
      // Send the UID as the response
      response.status(200).send({uid: userRecord.uid});
    } catch (error) {
      console.error("Error fetching user data:", error);
      response.status(500).send("Error fetching user data");
    }
  }
);
