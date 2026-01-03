/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// This would be your actual Mastercard Gateway API endpoint
const GATEWAY_API_URL = "https://na.gateway.mastercard.com/api/rest";
const MERCHANT_ID = "your_merchant_id";
const API_PASSWORD = "your_api_password";

exports.createPaymentSession = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  try {
    // Create a session
    const sessionResponse = await axios.post(
      `${GATEWAY_API_URL}/version/61/merchant/${MERCHANT_ID}/session`,
      {},
      {
        auth: {
          username: `merchant.${MERCHANT_ID}`,
          password: API_PASSWORD
        }
      }
    );

    // Get the session ID
    const sessionId = sessionResponse.data.session.id;

    // Update the session with order details
    await axios.put(
      `${GATEWAY_API_URL}/version/61/merchant/${MERCHANT_ID}/session/${sessionId}`,
      {
        order: {
          id: data.orderId,
          amount: data.amount,
          currency: data.currency
        },
        authentication: {
          acceptVersions: "3DS2",
          channel: "PAYER_APP",
          purpose: "PAYMENT_TRANSACTION"
        }
      },
      {
        auth: {
          username: `merchant.${MERCHANT_ID}`,
          password: API_PASSWORD
        }
      }
    );

    // Return the session ID to the client
    return { sessionId };
  } catch (error) {
    console.error("Error creating payment session:", error);
    throw new functions.https.HttpsError("internal", "Failed to create payment session");
  }
});

// Verify a purchase with Google Play
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to verify purchases.'
    );
  }

  const { purchaseToken, productId, packageName } = data;
  
  if (!purchaseToken || !productId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required purchase information.'
    );
  }

  try {
    // Set up Google Play API client
    const jwtClient = new google.auth.JWT(
      process.env.GOOGLE_CLIENT_EMAIL,
      null,
      process.env.GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      ['https://www.googleapis.com/auth/androidpublisher']
    );
    
    await jwtClient.authorize();
    
    const androidPublisher = google.androidpublisher({
      version: 'v3',
      auth: jwtClient
    });
    
    let purchaseData;
    
    // Check if this is a subscription or one-time product
    if (productId.includes('subscription') || productId.includes('premium')) {
      // Verify subscription purchase
      purchaseData = await androidPublisher.purchases.subscriptions.get({
        packageName: packageName || 'com.yourcompany.datingapp', // Fallback package name
        subscriptionId: productId,
        token: purchaseToken
      });
    } else {
      // Verify one-time purchase
      purchaseData = await androidPublisher.purchases.products.get({
        packageName: packageName || 'com.yourcompany.datingapp', // Fallback package name
        productId: productId,
        token: purchaseToken
      });
    }

    // Update user's premium status in Firestore
    if (purchaseData.data) {
      const userId = context.auth.uid;
      const isPremium = productId.includes('premium') && 
                       (purchaseData.data.paymentState === 1 || 
                        purchaseData.data.autoRenewing === true);
      
      if (isPremium) {
        await admin.firestore().collection('users').doc(userId).update({
          isPremium: true,
          premiumExpiryDate: purchaseData.data.expiryTimeMillis ? 
            new Date(parseInt(purchaseData.data.expiryTimeMillis)) : 
            new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Default to 30 days if no expiry
          purchaseToken: purchaseToken,
          productId: productId
        });
      }
      
      return {
        valid: true,
        isPremium: isPremium,
        purchaseData: purchaseData.data
      };
    }
    
    return { valid: false };
  } catch (error) {
    console.error('Purchase verification error:', error);
    
    // Return more detailed error information
    throw new functions.https.HttpsError(
      'internal',
      `Error verifying purchase: ${error.message || 'Unknown error'}`,
      {
        code: error.code || 'unknown',
        details: error.details || {}
      }
    );
  }
});
