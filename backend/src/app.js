const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { connectDB } = require('./config/database');
const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');
const authMiddleware = require('./middleware/auth');

// Route imports
const authRoutes = require('./routes/auth');
const recipeRoutes = require('./routes/recipes');
const tdeeRoutes = require('./routes/tdee');
const workoutRoutes = require('./routes/workouts');
const trackerRoutes = require('./routes/tracker');
const achievementRoutes = require('./routes/achievements');
const socialRoutes = require('./routes/social');
const adminRoutes = require('./routes/admin');
const analyticsRoutes = require('./routes/analytics');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000) / 60000)
  }
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    version: require('../package.json').version
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/recipes', authMiddleware, recipeRoutes);
app.use('/api/tdee', authMiddleware, tdeeRoutes);
app.use('/api/workouts', authMiddleware, workoutRoutes);
app.use('/api/tracker', authMiddleware, trackerRoutes);
app.use('/api/achievements', authMiddleware, achievementRoutes);
app.use('/api/social', authMiddleware, socialRoutes);
app.use('/api/admin', authMiddleware, adminRoutes);
app.use('/api/analytics', authMiddleware, analyticsRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Global error handler
app.use(errorHandler);

// Graceful shutdown handler
const gracefulShutdown = (signal) => {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  
  server.close(() => {
    logger.info('Process terminated gracefully');
    process.exit(0);
  });

  // Force close after 10 seconds
  setTimeout(() => {
    logger.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

// Initialize services and start server
const startServer = async () => {
  try {
    // Initialize Firebase and Firestore
    await connectDB();
    
    const server = app.listen(PORT, () => {
      logger.info(`🚀 Trego Backend Server running on port ${PORT}`);
      logger.info(`📱 Environment: ${process.env.NODE_ENV}`);
      logger.info(`🔗 Health check: http://localhost:${PORT}/health`);
    });

    // Handle graceful shutdown
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    
    return server;
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server if this file is run directly
if (require.main === module) {
  startServer();
}

module.exports = app;