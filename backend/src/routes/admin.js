const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { adminMiddleware } = require('../middleware/auth');
const { getFirestore } = require('../config/firebase');
const { cache } = require('../config/redis');
const logger = require('../utils/logger');

const router = express.Router();

// All admin routes require admin privileges
router.use(adminMiddleware);

// Get system overview dashboard
router.get('/dashboard', async (req, res, next) => {
  try {
    const firestore = getFirestore();
    const now = new Date();
    const lastWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const lastMonth = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Get user statistics
    const [
      totalUsersSnapshot,
      activeUsersSnapshot,
      newUsersSnapshot,
      totalPostsSnapshot,
      totalChallengesSnapshot,
      totalAchievementsSnapshot
    ] = await Promise.all([
      firestore.collection('users').get(),
      firestore.collection('users').where('lastLoginAt', '>=', lastWeek).get(),
      firestore.collection('users').where('createdAt', '>=', lastWeek).get(),
      firestore.collection('posts').get(),
      firestore.collection('challenges').get(),
      firestore.collectionGroup('achievements').get()
    ]);

    // Get system metrics from cache
    const systemMetrics = await cache.get('admin:system_metrics') || {
      apiCalls: 0,
      errors: 0,
      averageResponseTime: 0
    };

    const dashboard = {
      users: {
        total: totalUsersSnapshot.size,
        activeLastWeek: activeUsersSnapshot.size,
        newLastWeek: newUsersSnapshot.size,
        growthRate: totalUsersSnapshot.size > 0 
          ? ((newUsersSnapshot.size / totalUsersSnapshot.size) * 100).toFixed(2)
          : 0
      },
      content: {
        totalPosts: totalPostsSnapshot.size,
        totalChallenges: totalChallengesSnapshot.size,
        totalAchievements: totalAchievementsSnapshot.size
      },
      system: {
        apiCalls: systemMetrics.apiCalls,
        errorRate: systemMetrics.errors > 0 
          ? ((systemMetrics.errors / systemMetrics.apiCalls) * 100).toFixed(2)
          : 0,
        averageResponseTime: systemMetrics.averageResponseTime
      },
      timestamp: new Date().toISOString()
    };

    res.json({
      success: true,
      data: dashboard
    });

  } catch (error) {
    next(error);
  }
});

// Get user management data
router.get('/users', [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 }),
  query('search').optional().isString(),
  query('status').optional().isIn(['all', 'active', 'inactive', 'banned'])
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      limit = 20,
      offset = 0,
      search = '',
      status = 'all'
    } = req.query;

    const firestore = getFirestore();
    let query = firestore.collection('users');

    // Apply status filter
    if (status !== 'all') {
      if (status === 'active') {
        query = query.where('isActive', '==', true);
      } else if (status === 'inactive') {
        query = query.where('isActive', '==', false);
      } else if (status === 'banned') {
        query = query.where('isBanned', '==', true);
      }
    }

    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .offset(parseInt(offset))
      .limit(parseInt(limit))
      .get();

    let users = snapshot.docs.map(doc => {
      const userData = doc.data();
      return {
        uid: userData.uid,
        name: userData.name,
        email: userData.email,
        subscription: userData.subscription || 'free',
        isActive: userData.isActive !== false,
        isBanned: userData.isBanned || false,
        createdAt: userData.createdAt?.toDate?.()?.toISOString() || userData.createdAt,
        lastLoginAt: userData.lastLoginAt?.toDate?.()?.toISOString() || userData.lastLoginAt
      };
    });

    // Apply search filter (client-side for simplicity)
    if (search) {
      const searchLower = search.toLowerCase();
      users = users.filter(user => 
        user.name?.toLowerCase().includes(searchLower) ||
        user.email?.toLowerCase().includes(searchLower)
      );
    }

    res.json({
      success: true,
      data: {
        users,
        total: users.length,
        hasMore: snapshot.size === parseInt(limit)
      }
    });

  } catch (error) {
    next(error);
  }
});

// Update user status (ban/unban/activate/deactivate)
router.put('/users/:userId/status', [
  body('action').isIn(['ban', 'unban', 'activate', 'deactivate']).withMessage('Invalid action'),
  body('reason').optional().isString().withMessage('Reason must be a string')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { userId } = req.params;
    const { action, reason = '' } = req.body;

    const firestore = getFirestore();
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const updates = {
      updatedAt: new Date()
    };

    switch (action) {
      case 'ban':
        updates.isBanned = true;
        updates.bannedAt = new Date();
        updates.bannedBy = req.user.uid;
        updates.banReason = reason;
        break;
      case 'unban':
        updates.isBanned = false;
        updates.unbannedAt = new Date();
        updates.unbannedBy = req.user.uid;
        break;
      case 'activate':
        updates.isActive = true;
        break;
      case 'deactivate':
        updates.isActive = false;
        updates.deactivatedAt = new Date();
        updates.deactivatedBy = req.user.uid;
        updates.deactivationReason = reason;
        break;
    }

    await userDoc.ref.update(updates);

    // Log admin action
    await firestore.collection('admin_logs').add({
      adminId: req.user.uid,
      adminName: req.user.name,
      action: `user_${action}`,
      targetUserId: userId,
      targetUserName: userDoc.data().name,
      reason,
      timestamp: new Date()
    });

    logger.info('Admin user status update', {
      adminId: req.user.uid,
      targetUserId: userId,
      action,
      reason
    });

    res.json({
      success: true,
      message: `User ${action} successful`
    });

  } catch (error) {
    next(error);
  }
});

// Get content moderation queue
router.get('/content/moderation', [
  query('type').optional().isIn(['posts', 'challenges', 'reports']),
  query('status').optional().isIn(['pending', 'approved', 'rejected', 'all'])
], async (req, res, next) => {
  try {
    const {
      type = 'posts',
      status = 'pending',
      limit = 50
    } = req.query;

    const firestore = getFirestore();
    
    let items = [];

    if (type === 'posts' || type === 'all') {
      let postsQuery = firestore.collection('posts');
      
      if (status !== 'all') {
        postsQuery = postsQuery.where('moderationStatus', '==', status);
      }

      const postsSnapshot = await postsQuery
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      const posts = postsSnapshot.docs.map(doc => ({
        id: doc.id,
        type: 'post',
        ...doc.data(),
        createdAt: doc.data().createdAt.toDate().toISOString()
      }));

      items = [...items, ...posts];
    }

    if (type === 'challenges' || type === 'all') {
      let challengesQuery = firestore.collection('challenges');
      
      if (status !== 'all') {
        challengesQuery = challengesQuery.where('moderationStatus', '==', status);
      }

      const challengesSnapshot = await challengesQuery
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      const challenges = challengesSnapshot.docs.map(doc => ({
        id: doc.id,
        type: 'challenge',
        ...doc.data(),
        createdAt: doc.data().createdAt.toDate().toISOString()
      }));

      items = [...items, ...challenges];
    }

    // Sort by creation date
    items.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({
      success: true,
      data: {
        items: items.slice(0, limit),
        total: items.length,
        filters: { type, status }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Moderate content (approve/reject)
router.put('/content/:contentType/:contentId/moderate', [
  body('action').isIn(['approve', 'reject']).withMessage('Invalid action'),
  body('reason').optional().isString().withMessage('Reason must be a string')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { contentType, contentId } = req.params;
    const { action, reason = '' } = req.body;

    if (!['posts', 'challenges'].includes(contentType)) {
      return res.status(400).json({
        error: 'Invalid content type'
      });
    }

    const firestore = getFirestore();
    const contentDoc = await firestore
      .collection(contentType)
      .doc(contentId)
      .get();

    if (!contentDoc.exists) {
      return res.status(404).json({
        error: 'Content not found'
      });
    }

    const updates = {
      moderationStatus: action === 'approve' ? 'approved' : 'rejected',
      moderatedAt: new Date(),
      moderatedBy: req.user.uid,
      moderationReason: reason
    };

    await contentDoc.ref.update(updates);

    // Log moderation action
    await firestore.collection('admin_logs').add({
      adminId: req.user.uid,
      adminName: req.user.name,
      action: `content_${action}`,
      contentType,
      contentId,
      reason,
      timestamp: new Date()
    });

    // Notify content creator if rejected
    if (action === 'reject') {
      const contentData = contentDoc.data();
      const creatorId = contentData.authorId || contentData.creatorId;
      
      if (creatorId) {
        await firestore
          .collection('users')
          .doc(creatorId)
          .collection('notifications')
          .add({
            type: 'content_rejected',
            message: `Your ${contentType.slice(0, -1)} was rejected by moderation`,
            data: { contentType, contentId, reason },
            read: false,
            createdAt: new Date()
          });
      }
    }

    logger.info('Content moderation action', {
      adminId: req.user.uid,
      contentType,
      contentId,
      action,
      reason
    });

    res.json({
      success: true,
      message: `Content ${action}d successfully`
    });

  } catch (error) {
    next(error);
  }
});

// Get system analytics
router.get('/analytics', [
  query('period').optional().isIn(['day', 'week', 'month', 'year']),
  query('metric').optional().isIn(['users', 'content', 'activity', 'all'])
], async (req, res, next) => {
  try {
    const { period = 'week', metric = 'all' } = req.query;
    
    const now = new Date();
    let startDate;
    
    switch (period) {
      case 'day':
        startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        break;
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
        break;
    }

    const firestore = getFirestore();
    const analytics = {};

    if (metric === 'users' || metric === 'all') {
      const [newUsersSnapshot, activeUsersSnapshot] = await Promise.all([
        firestore.collection('users').where('createdAt', '>=', startDate).get(),
        firestore.collection('users').where('lastLoginAt', '>=', startDate).get()
      ]);

      analytics.users = {
        newUsers: newUsersSnapshot.size,
        activeUsers: activeUsersSnapshot.size,
        retention: activeUsersSnapshot.size > 0 ? 
          ((activeUsersSnapshot.size / newUsersSnapshot.size) * 100).toFixed(2) : 0
      };
    }

    if (metric === 'content' || metric === 'all') {
      const [postsSnapshot, challengesSnapshot] = await Promise.all([
        firestore.collection('posts').where('createdAt', '>=', startDate).get(),
        firestore.collection('challenges').where('createdAt', '>=', startDate).get()
      ]);

      analytics.content = {
        newPosts: postsSnapshot.size,
        newChallenges: challengesSnapshot.size,
        totalNewContent: postsSnapshot.size + challengesSnapshot.size
      };
    }

    if (metric === 'activity' || metric === 'all') {
      const [workoutsSnapshot, runsSnapshot] = await Promise.all([
        firestore.collectionGroup('workout_completions').where('completedAt', '>=', startDate).get(),
        firestore.collectionGroup('runs').where('completedAt', '>=', startDate).get()
      ]);

      analytics.activity = {
        totalWorkouts: workoutsSnapshot.size,
        totalRuns: runsSnapshot.size,
        totalActivities: workoutsSnapshot.size + runsSnapshot.size
      };
    }

    res.json({
      success: true,
      data: {
        period,
        startDate: startDate.toISOString(),
        endDate: now.toISOString(),
        analytics
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get admin logs
router.get('/logs', [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('action').optional().isString(),
  query('adminId').optional().isString()
], async (req, res, next) => {
  try {
    const {
      limit = 50,
      action,
      adminId
    } = req.query;

    const firestore = getFirestore();
    let query = firestore.collection('admin_logs');

    if (action) {
      query = query.where('action', '==', action);
    }

    if (adminId) {
      query = query.where('adminId', '==', adminId);
    }

    const snapshot = await query
      .orderBy('timestamp', 'desc')
      .limit(parseInt(limit))
      .get();

    const logs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp.toDate().toISOString()
    }));

    res.json({
      success: true,
      data: {
        logs,
        total: logs.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// System configuration
router.get('/config', async (req, res, next) => {
  try {
    const firestore = getFirestore();
    const configDoc = await firestore.collection('system').doc('config').get();

    const defaultConfig = {
      maintenanceMode: false,
      maxUsersPerChallenge: 100,
      postModerationEnabled: true,
      challengeModerationEnabled: true,
      newUserRegistrationEnabled: true,
      maxPostsPerDay: 10,
      maxChallengesPerUser: 5
    };

    const config = configDoc.exists ? { ...defaultConfig, ...configDoc.data() } : defaultConfig;

    res.json({
      success: true,
      data: config
    });

  } catch (error) {
    next(error);
  }
});

// Update system configuration
router.put('/config', [
  body('maintenanceMode').optional().isBoolean(),
  body('maxUsersPerChallenge').optional().isInt({ min: 10, max: 1000 }),
  body('postModerationEnabled').optional().isBoolean(),
  body('challengeModerationEnabled').optional().isBoolean(),
  body('newUserRegistrationEnabled').optional().isBoolean(),
  body('maxPostsPerDay').optional().isInt({ min: 1, max: 100 }),
  body('maxChallengesPerUser').optional().isInt({ min: 1, max: 50 })
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
    updates.updatedBy = req.user.uid;

    const firestore = getFirestore();
    await firestore
      .collection('system')
      .doc('config')
      .set(updates, { merge: true });

    // Log configuration change
    await firestore.collection('admin_logs').add({
      adminId: req.user.uid,
      adminName: req.user.name,
      action: 'config_update',
      changes: updates,
      timestamp: new Date()
    });

    logger.info('System configuration updated', {
      adminId: req.user.uid,
      changes: Object.keys(updates)
    });

    res.json({
      success: true,
      message: 'Configuration updated successfully'
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;