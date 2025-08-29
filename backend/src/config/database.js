const { initializeFirebase, getFirestore } = require('./firebase');
const logger = require('../utils/logger');

const connectDB = async () => {
  try {
    // Initialize Firebase instead of MongoDB
    await initializeFirebase();
    
    // Test Firestore connection
    const db = getFirestore();
    await db.collection('_health').doc('check').set({
      timestamp: new Date(),
      status: 'connected'
    });
    
    logger.info('📁 Firestore Connected Successfully');

    return db;
  } catch (error) {
    logger.error('Firestore connection failed:', error);
    process.exit(1);
  }
};

module.exports = { connectDB };