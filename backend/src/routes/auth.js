const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { firebaseUtils, getFirestore } = require('../config/firebase');
const logger = require('../utils/logger');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Validation middleware
const validateRegistration = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email required'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain uppercase, lowercase, and number'),
  body('name')
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('age')
    .optional()
    .isInt({ min: 13, max: 120 })
    .withMessage('Age must be between 13 and 120'),
  body('gender')
    .optional()
    .isIn(['male', 'female', 'other', 'prefer-not-to-say'])
    .withMessage('Invalid gender selection')
];

const validateLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email required'),
  body('password')
    .notEmpty()
    .withMessage('Password required')
];

// Register new user (backup to Firebase Auth)
router.post('/register', validateRegistration, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password, name, age, gender } = req.body;
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);
    
    // Create user document in Firestore
    const firestore = getFirestore();
    const userRef = firestore.collection('users').doc();
    
    const userData = {
      uid: userRef.id,
      email,
      password: hashedPassword,
      name,
      age: age || null,
      gender: gender || null,
      createdAt: new Date(),
      updatedAt: new Date(),
      emailVerified: false,
      isActive: true,
      subscription: 'free',
      preferences: {
        units: 'metric',
        notifications: true,
        privacy: 'friends'
      }
    };
    
    await userRef.set(userData);
    
    // Create JWT token
    const token = jwt.sign(
      { 
        uid: userRef.id, 
        email, 
        name,
        subscription: 'free'
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    logger.info('User registered successfully', { uid: userRef.id, email });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: {
        uid: userRef.id,
        email,
        name,
        subscription: 'free',
        emailVerified: false
      }
    });

  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        error: 'User already exists',
        message: 'An account with this email already exists'
      });
    }
    next(error);
  }
});

// Login user
router.post('/login', validateLogin, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;
    
    // Find user in Firestore
    const firestore = getFirestore();
    const usersRef = firestore.collection('users');
    const userQuery = await usersRef.where('email', '==', email).limit(1).get();
    
    if (userQuery.empty) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid email or password'
      });
    }
    
    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();
    
    // Check password
    const isPasswordValid = await bcrypt.compare(password, userData.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid email or password'
      });
    }
    
    // Check if user is active
    if (!userData.isActive) {
      return res.status(401).json({
        error: 'Account deactivated',
        message: 'Your account has been deactivated. Please contact support.'
      });
    }
    
    // Update last login
    await userDoc.ref.update({
      lastLoginAt: new Date(),
      updatedAt: new Date()
    });
    
    // Create JWT token
    const token = jwt.sign(
      { 
        uid: userData.uid, 
        email: userData.email, 
        name: userData.name,
        subscription: userData.subscription || 'free',
        emailVerified: userData.emailVerified || false
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    logger.info('User logged in successfully', { uid: userData.uid, email });

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        uid: userData.uid,
        email: userData.email,
        name: userData.name,
        subscription: userData.subscription || 'free',
        emailVerified: userData.emailVerified || false,
        lastLoginAt: new Date()
      }
    });

  } catch (error) {
    next(error);
  }
});

// Verify Firebase token and sync with backend
router.post('/firebase-sync', async (req, res, next) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      return res.status(400).json({
        error: 'Firebase ID token required'
      });
    }

    // Verify Firebase token
    const decodedToken = await firebaseUtils.verifyIdToken(idToken);
    
    // Check if user exists in our backend
    const firestore = getFirestore();
    const userDoc = await firestore.collection('users').doc(decodedToken.uid).get();
    
    let userData;
    
    if (!userDoc.exists) {
      // Create new user document
      userData = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        name: decodedToken.name || decodedToken.email.split('@')[0],
        emailVerified: decodedToken.email_verified,
        picture: decodedToken.picture,
        provider: decodedToken.firebase.sign_in_provider,
        createdAt: new Date(),
        updatedAt: new Date(),
        isActive: true,
        subscription: 'free',
        preferences: {
          units: 'metric',
          notifications: true,
          privacy: 'friends'
        }
      };
      
      await firestore.collection('users').doc(decodedToken.uid).set(userData);
      logger.info('New Firebase user synced', { uid: decodedToken.uid, provider: userData.provider });
    } else {
      userData = userDoc.data();
      
      // Update last login
      await userDoc.ref.update({
        lastLoginAt: new Date(),
        updatedAt: new Date()
      });
      
      logger.info('Existing Firebase user synced', { uid: decodedToken.uid });
    }
    
    // Create our own JWT token for consistency
    const backendToken = jwt.sign(
      { 
        uid: userData.uid, 
        email: userData.email, 
        name: userData.name,
        subscription: userData.subscription || 'free',
        emailVerified: userData.emailVerified || false,
        firebase: true
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.json({
      success: true,
      message: 'Firebase user synced successfully',
      token: backendToken,
      user: {
        uid: userData.uid,
        email: userData.email,
        name: userData.name,
        subscription: userData.subscription || 'free',
        emailVerified: userData.emailVerified || false,
        picture: userData.picture,
        provider: userData.provider
      }
    });

  } catch (error) {
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        error: 'Token expired',
        message: 'Please sign in again'
      });
    }
    next(error);
  }
});

// Get current user profile
router.get('/profile', authMiddleware, async (req, res, next) => {
  try {
    const firestore = getFirestore();
    const userDoc = await firestore.collection('users').doc(req.user.uid).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({
        error: 'User not found',
        message: 'User profile does not exist'
      });
    }
    
    const userData = userDoc.data();
    
    // Remove sensitive data
    const { password, ...safeUserData } = userData;
    
    res.json({
      success: true,
      user: safeUserData
    });

  } catch (error) {
    next(error);
  }
});

// Update user profile
router.put('/profile', authMiddleware, [
  body('name').optional().isLength({ min: 2, max: 50 }),
  body('age').optional().isInt({ min: 13, max: 120 }),
  body('gender').optional().isIn(['male', 'female', 'other', 'prefer-not-to-say']),
  body('preferences.units').optional().isIn(['metric', 'imperial']),
  body('preferences.notifications').optional().isBoolean(),
  body('preferences.privacy').optional().isIn(['public', 'friends', 'private'])
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const updates = req.body;
    updates.updatedAt = new Date();
    
    const firestore = getFirestore();
    await firestore.collection('users').doc(req.user.uid).update(updates);
    
    logger.info('User profile updated', { uid: req.user.uid });

    res.json({
      success: true,
      message: 'Profile updated successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Logout (invalidate token on client side)
router.post('/logout', authMiddleware, (req, res) => {
  logger.info('User logged out', { uid: req.user.uid });
  
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

module.exports = router;