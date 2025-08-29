const jwt = require('jsonwebtoken');
const { firebaseUtils } = require('../config/firebase');
const logger = require('../utils/logger');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Access denied',
        message: 'No token provided or invalid format'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Try Firebase ID token verification first
    try {
      const decodedToken = await firebaseUtils.verifyIdToken(token);
      
      // Add user info to request object
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        name: decodedToken.name,
        picture: decodedToken.picture,
        firebase: true,
        customClaims: decodedToken
      };

      return next();
    } catch (firebaseError) {
      // If Firebase token fails, try JWT token
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = {
          uid: decoded.uid,
          email: decoded.email,
          name: decoded.name,
          firebase: false,
          ...decoded
        };
        return next();
      } catch (jwtError) {
        logger.warn('Token verification failed:', {
          firebase: firebaseError.message,
          jwt: jwtError.message,
          ip: req.ip
        });
        
        return res.status(401).json({
          error: 'Access denied',
          message: 'Invalid or expired token'
        });
      }
    }
  } catch (error) {
    logger.error('Auth middleware error:', error);
    return res.status(500).json({
      error: 'Authentication error',
      message: 'Internal server error during authentication'
    });
  }
};

// Middleware for admin-only routes
const adminMiddleware = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      error: 'Access denied',
      message: 'Authentication required'
    });
  }

  // Check for admin role in custom claims
  const isAdmin = req.user.customClaims?.admin === true || 
                 req.user.role === 'admin' ||
                 req.user.isAdmin === true;

  if (!isAdmin) {
    return res.status(403).json({
      error: 'Access forbidden',
      message: 'Admin privileges required'
    });
  }

  next();
};

// Middleware for premium features
const premiumMiddleware = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      error: 'Access denied',
      message: 'Authentication required'
    });
  }

  const isPremium = req.user.customClaims?.premium === true || 
                   req.user.subscription === 'premium' ||
                   req.user.isPremium === true;

  if (!isPremium) {
    return res.status(403).json({
      error: 'Premium subscription required',
      message: 'This feature requires a premium subscription'
    });
  }

  next();
};

// Optional auth middleware (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  try {
    const token = authHeader.substring(7);
    const decodedToken = await firebaseUtils.verifyIdToken(token);
    
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      name: decodedToken.name,
      picture: decodedToken.picture,
      firebase: true,
      customClaims: decodedToken
    };
  } catch (error) {
    // Silently continue without user context
    logger.debug('Optional auth failed:', error.message);
  }

  next();
};

module.exports = {
  authMiddleware,
  adminMiddleware,
  premiumMiddleware,
  optionalAuth
};