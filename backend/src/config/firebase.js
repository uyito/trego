const admin = require('firebase-admin');
const logger = require('../utils/logger');

let firebaseApp = null;

const initializeFirebase = () => {
  try {
    // Check if Firebase is already initialized
    if (firebaseApp) {
      return firebaseApp;
    }

    const serviceAccount = {
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_uri: 'https://oauth2.googleapis.com/token',
      auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
      client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`
    };

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL,
      storageBucket: `${process.env.FIREBASE_PROJECT_ID}.appspot.com`
    });

    logger.info('🔥 Firebase Admin SDK initialized successfully');
    
    return firebaseApp;
  } catch (error) {
    logger.error('Firebase initialization failed:', error);
    throw error;
  }
};

const getFirebaseApp = () => {
  if (!firebaseApp) {
    throw new Error('Firebase not initialized. Call initializeFirebase() first.');
  }
  return firebaseApp;
};

const getFirestore = () => {
  return getFirebaseApp().firestore();
};

const getAuth = () => {
  return getFirebaseApp().auth();
};

const getStorage = () => {
  return getFirebaseApp().storage();
};

// Utility functions for Firebase operations
const firebaseUtils = {
  async verifyIdToken(idToken) {
    try {
      const decodedToken = await getAuth().verifyIdToken(idToken);
      return decodedToken;
    } catch (error) {
      logger.error('Token verification failed:', error);
      throw new Error('Invalid token');
    }
  },

  async getUserByUid(uid) {
    try {
      const userRecord = await getAuth().getUser(uid);
      return userRecord;
    } catch (error) {
      logger.error('Failed to get user by UID:', error);
      return null;
    }
  },

  async createCustomToken(uid, additionalClaims = {}) {
    try {
      const customToken = await getAuth().createCustomToken(uid, additionalClaims);
      return customToken;
    } catch (error) {
      logger.error('Failed to create custom token:', error);
      throw error;
    }
  },

  async setCustomUserClaims(uid, customClaims) {
    try {
      await getAuth().setCustomUserClaims(uid, customClaims);
      return true;
    } catch (error) {
      logger.error('Failed to set custom user claims:', error);
      throw error;
    }
  }
};

module.exports = {
  initializeFirebase,
  getFirebaseApp,
  getFirestore,
  getAuth,
  getStorage,
  firebaseUtils
};