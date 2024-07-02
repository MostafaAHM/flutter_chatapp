const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
    const recipientId = data.recipientId;
    const messageText = data.messageText;
    const senderEmail = data.senderEmail;

    try {
        const tokensSnapshot = await admin.firestore().collection('users').doc(recipientId).collection('tokens').get();
        const tokens = tokensSnapshot.docs.map(doc => doc.id);

        const payload = {
            notification: {
                title: 'New Message',
                body: `${senderEmail}: ${messageText}`,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        await admin.messaging().sendToDevice(tokens, payload);
        console.log('Notification sent successfully');
        return { success: true };
    } catch (error) {
        console.error('Error sending notification:', error);
        throw new functions.https.HttpsError('internal', 'Notification sending failed');
    }
});

