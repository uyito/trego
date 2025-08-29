const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { getFirestore } = require('../config/firebase');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateFriendRequest = [
  body('friendId')
    .isString()
    .isLength({ min: 1 })
    .withMessage('Friend ID is required'),
  body('message')
    .optional()
    .isLength({ max: 200 })
    .withMessage('Message must be less than 200 characters')
];

const validateChallengeCreation = [
  body('title')
    .isString()
    .isLength({ min: 3, max: 100 })
    .withMessage('Title must be between 3 and 100 characters'),
  body('description')
    .isString()
    .isLength({ min: 10, max: 500 })
    .withMessage('Description must be between 10 and 500 characters'),
  body('type')
    .isIn(['distance', 'workouts', 'calories', 'streak'])
    .withMessage('Invalid challenge type'),
  body('target')
    .isInt({ min: 1 })
    .withMessage('Target must be a positive integer'),
  body('duration')
    .isInt({ min: 1, max: 365 })
    .withMessage('Duration must be between 1 and 365 days'),
  body('isPublic')
    .optional()
    .isBoolean()
    .withMessage('isPublic must be a boolean'),
  body('maxParticipants')
    .optional()
    .isInt({ min: 2, max: 100 })
    .withMessage('Max participants must be between 2 and 100')
];

const validatePost = [
  body('content')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Content must be less than 1000 characters'),
  body('type')
    .isIn(['achievement', 'workout', 'run', 'general'])
    .withMessage('Invalid post type'),
  body('attachments')
    .optional()
    .isArray()
    .withMessage('Attachments must be an array'),
  body('visibility')
    .optional()
    .isIn(['public', 'friends', 'private'])
    .withMessage('Invalid visibility setting')
];

// Get user's social profile
router.get('/profile', async (req, res, next) => {
  try {
    const firestore = getFirestore();
    
    // Get user's profile
    const userDoc = await firestore
      .collection('users')
      .doc(req.user.uid)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    const userData = userDoc.data();
    
    // Get social stats
    const [friendsSnapshot, achievementsSnapshot, postsSnapshot] = await Promise.all([
      firestore.collection('friendships').where('userId', '==', req.user.uid).where('status', '==', 'accepted').get(),
      firestore.collection('users').doc(req.user.uid).collection('achievements').doc('summary').get(),
      firestore.collection('posts').where('authorId', '==', req.user.uid).get()
    ]);

    const profile = {
      uid: req.user.uid,
      name: userData.name,
      picture: userData.picture,
      bio: userData.bio || '',
      joinedAt: userData.createdAt,
      stats: {
        friends: friendsSnapshot.size,
        achievements: achievementsSnapshot.exists ? achievementsSnapshot.data().totalAchievements : 0,
        posts: postsSnapshot.size,
        points: achievementsSnapshot.exists ? achievementsSnapshot.data().totalPoints : 0
      },
      settings: {
        privacy: userData.preferences?.privacy || 'friends',
        showStats: userData.preferences?.showStats !== false,
        showActivity: userData.preferences?.showActivity !== false
      }
    };

    res.json({
      success: true,
      data: profile
    });

  } catch (error) {
    next(error);
  }
});

// Send friend request
router.post('/friends/request', validateFriendRequest, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { friendId, message = '' } = req.body;
    
    if (friendId === req.user.uid) {
      return res.status(400).json({
        error: 'Cannot send friend request to yourself'
      });
    }

    const firestore = getFirestore();
    
    // Check if friendship already exists
    const existingFriendship = await firestore
      .collection('friendships')
      .where('userId', 'in', [req.user.uid, friendId])
      .where('friendId', 'in', [req.user.uid, friendId])
      .get();

    if (!existingFriendship.empty) {
      return res.status(400).json({
        error: 'Friendship request already exists or you are already friends'
      });
    }

    // Create friend request
    const requestData = {
      userId: req.user.uid,
      friendId,
      status: 'pending',
      message,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    await firestore
      .collection('friendships')
      .add(requestData);

    // Create notification for recipient
    await firestore
      .collection('users')
      .doc(friendId)
      .collection('notifications')
      .add({
        type: 'friend_request',
        fromUserId: req.user.uid,
        fromUserName: req.user.name,
        message: `${req.user.name} sent you a friend request`,
        data: { message },
        read: false,
        createdAt: new Date()
      });

    logger.info('Friend request sent', {
      fromUserId: req.user.uid,
      toUserId: friendId
    });

    res.json({
      success: true,
      message: 'Friend request sent successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Respond to friend request
router.post('/friends/respond/:requestId', [
  body('action').isIn(['accept', 'decline']).withMessage('Action must be accept or decline')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { requestId } = req.params;
    const { action } = req.body;

    const firestore = getFirestore();
    const requestDoc = await firestore
      .collection('friendships')
      .doc(requestId)
      .get();

    if (!requestDoc.exists) {
      return res.status(404).json({
        error: 'Friend request not found'
      });
    }

    const requestData = requestDoc.data();
    
    if (requestData.friendId !== req.user.uid) {
      return res.status(403).json({
        error: 'You can only respond to requests sent to you'
      });
    }

    if (requestData.status !== 'pending') {
      return res.status(400).json({
        error: 'Request has already been responded to'
      });
    }

    if (action === 'accept') {
      // Update request status
      await requestDoc.ref.update({
        status: 'accepted',
        updatedAt: new Date()
      });

      // Create reverse friendship
      await firestore
        .collection('friendships')
        .add({
          userId: requestData.friendId,
          friendId: requestData.userId,
          status: 'accepted',
          createdAt: new Date(),
          updatedAt: new Date()
        });

      // Notify requester
      await firestore
        .collection('users')
        .doc(requestData.userId)
        .collection('notifications')
        .add({
          type: 'friend_accepted',
          fromUserId: req.user.uid,
          fromUserName: req.user.name,
          message: `${req.user.name} accepted your friend request`,
          read: false,
          createdAt: new Date()
        });

      logger.info('Friend request accepted', {
        requesterId: requestData.userId,
        accepterId: req.user.uid
      });

      res.json({
        success: true,
        message: 'Friend request accepted'
      });
    } else {
      // Decline request
      await requestDoc.ref.update({
        status: 'declined',
        updatedAt: new Date()
      });

      logger.info('Friend request declined', {
        requesterId: requestData.userId,
        declinerId: req.user.uid
      });

      res.json({
        success: true,
        message: 'Friend request declined'
      });
    }

  } catch (error) {
    next(error);
  }
});

// Get friends list
router.get('/friends', async (req, res, next) => {
  try {
    const firestore = getFirestore();
    
    const friendshipsSnapshot = await firestore
      .collection('friendships')
      .where('userId', '==', req.user.uid)
      .where('status', '==', 'accepted')
      .get();

    const friendIds = friendshipsSnapshot.docs.map(doc => doc.data().friendId);
    
    if (friendIds.length === 0) {
      return res.json({
        success: true,
        data: {
          friends: [],
          total: 0
        }
      });
    }

    // Get friend profiles (Firestore has a limit of 10 items for 'in' queries)
    const friends = [];
    const batchSize = 10;
    
    for (let i = 0; i < friendIds.length; i += batchSize) {
      const batch = friendIds.slice(i, i + batchSize);
      const usersSnapshot = await firestore
        .collection('users')
        .where('uid', 'in', batch)
        .get();
      
      usersSnapshot.docs.forEach(doc => {
        const userData = doc.data();
        friends.push({
          uid: userData.uid,
          name: userData.name,
          picture: userData.picture,
          lastActive: userData.lastLoginAt
        });
      });
    }

    res.json({
      success: true,
      data: {
        friends,
        total: friends.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// Create challenge
router.post('/challenges', validateChallengeCreation, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      title,
      description,
      type,
      target,
      duration,
      isPublic = true,
      maxParticipants = 50
    } = req.body;

    const firestore = getFirestore();
    
    const challengeData = {
      title,
      description,
      type,
      target,
      duration, // days
      isPublic,
      maxParticipants,
      creatorId: req.user.uid,
      creatorName: req.user.name,
      participants: [{
        userId: req.user.uid,
        name: req.user.name,
        joinedAt: new Date(),
        progress: 0
      }],
      status: 'active',
      startDate: new Date(),
      endDate: new Date(Date.now() + (duration * 24 * 60 * 60 * 1000)),
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const docRef = await firestore
      .collection('challenges')
      .add(challengeData);

    logger.info('Challenge created', {
      challengeId: docRef.id,
      creatorId: req.user.uid,
      type,
      duration
    });

    res.json({
      success: true,
      challengeId: docRef.id,
      message: 'Challenge created successfully!',
      data: {
        ...challengeData,
        id: docRef.id
      }
    });

  } catch (error) {
    next(error);
  }
});

// Join challenge
router.post('/challenges/:challengeId/join', async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    
    const firestore = getFirestore();
    const challengeDoc = await firestore
      .collection('challenges')
      .doc(challengeId)
      .get();

    if (!challengeDoc.exists) {
      return res.status(404).json({
        error: 'Challenge not found'
      });
    }

    const challengeData = challengeDoc.data();

    // Check if challenge is still active
    if (challengeData.status !== 'active') {
      return res.status(400).json({
        error: 'Challenge is not active'
      });
    }

    // Check if already participating
    const isParticipating = challengeData.participants.some(p => p.userId === req.user.uid);
    if (isParticipating) {
      return res.status(400).json({
        error: 'You are already participating in this challenge'
      });
    }

    // Check if challenge is full
    if (challengeData.participants.length >= challengeData.maxParticipants) {
      return res.status(400).json({
        error: 'Challenge is full'
      });
    }

    // Add user to participants
    const newParticipant = {
      userId: req.user.uid,
      name: req.user.name,
      joinedAt: new Date(),
      progress: 0
    };

    await challengeDoc.ref.update({
      participants: [...challengeData.participants, newParticipant],
      updatedAt: new Date()
    });

    logger.info('User joined challenge', {
      challengeId,
      userId: req.user.uid
    });

    res.json({
      success: true,
      message: 'Successfully joined challenge!'
    });

  } catch (error) {
    next(error);
  }
});

// Get challenges
router.get('/challenges', [
  query('type').optional().isIn(['distance', 'workouts', 'calories', 'streak']),
  query('status').optional().isIn(['active', 'completed', 'all']),
  query('scope').optional().isIn(['public', 'joined', 'created'])
], async (req, res, next) => {
  try {
    const { type, status = 'active', scope = 'public' } = req.query;
    
    const firestore = getFirestore();
    let query = firestore.collection('challenges');

    // Apply filters
    if (type) {
      query = query.where('type', '==', type);
    }

    if (status !== 'all') {
      query = query.where('status', '==', status);
    }

    if (scope === 'public') {
      query = query.where('isPublic', '==', true);
    } else if (scope === 'created') {
      query = query.where('creatorId', '==', req.user.uid);
    }

    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    let challenges = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      startDate: doc.data().startDate.toDate().toISOString(),
      endDate: doc.data().endDate.toDate().toISOString(),
      createdAt: doc.data().createdAt.toDate().toISOString()
    }));

    // Filter for joined challenges if needed
    if (scope === 'joined') {
      challenges = challenges.filter(challenge =>
        challenge.participants.some(p => p.userId === req.user.uid)
      );
    }

    res.json({
      success: true,
      data: {
        challenges,
        total: challenges.length,
        filters: { type, status, scope }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Create social post
router.post('/posts', validatePost, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      content = '',
      type,
      attachments = [],
      visibility = 'friends'
    } = req.body;

    const firestore = getFirestore();
    
    const postData = {
      authorId: req.user.uid,
      authorName: req.user.name,
      authorPicture: req.user.picture,
      content,
      type,
      attachments,
      visibility,
      likes: 0,
      comments: 0,
      shares: 0,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const docRef = await firestore
      .collection('posts')
      .add(postData);

    logger.info('Social post created', {
      postId: docRef.id,
      authorId: req.user.uid,
      type,
      visibility
    });

    res.json({
      success: true,
      postId: docRef.id,
      message: 'Post created successfully!',
      data: {
        ...postData,
        id: docRef.id
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get social feed
router.get('/feed', [
  query('limit').optional().isInt({ min: 1, max: 50 }),
  query('offset').optional().isInt({ min: 0 })
], async (req, res, next) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    
    const firestore = getFirestore();
    
    // Get user's friends to show their posts
    const friendshipsSnapshot = await firestore
      .collection('friendships')
      .where('userId', '==', req.user.uid)
      .where('status', '==', 'accepted')
      .get();

    const friendIds = friendshipsSnapshot.docs.map(doc => doc.data().friendId);
    friendIds.push(req.user.uid); // Include user's own posts

    // Get posts from friends and public posts
    let postsQuery = firestore
      .collection('posts')
      .where('visibility', 'in', ['public', 'friends'])
      .orderBy('createdAt', 'desc')
      .offset(parseInt(offset))
      .limit(parseInt(limit));

    const postsSnapshot = await postsQuery.get();

    const posts = postsSnapshot.docs
      .map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt.toDate().toISOString(),
        updatedAt: doc.data().updatedAt.toDate().toISOString()
      }))
      .filter(post => {
        // Show public posts or posts from friends
        return post.visibility === 'public' || 
               (post.visibility === 'friends' && friendIds.includes(post.authorId));
      });

    res.json({
      success: true,
      data: {
        posts,
        hasMore: postsSnapshot.size === parseInt(limit),
        total: posts.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// Like/unlike post
router.post('/posts/:postId/like', async (req, res, next) => {
  try {
    const { postId } = req.params;
    
    const firestore = getFirestore();
    const postDoc = await firestore
      .collection('posts')
      .doc(postId)
      .get();

    if (!postDoc.exists) {
      return res.status(404).json({
        error: 'Post not found'
      });
    }

    // Check if already liked
    const likeDoc = await firestore
      .collection('posts')
      .doc(postId)
      .collection('likes')
      .doc(req.user.uid)
      .get();

    if (likeDoc.exists) {
      // Unlike
      await likeDoc.ref.delete();
      await postDoc.ref.update({
        likes: postDoc.data().likes - 1,
        updatedAt: new Date()
      });

      res.json({
        success: true,
        message: 'Post unliked',
        liked: false
      });
    } else {
      // Like
      await firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(req.user.uid)
        .set({
          userId: req.user.uid,
          userName: req.user.name,
          createdAt: new Date()
        });

      await postDoc.ref.update({
        likes: postDoc.data().likes + 1,
        updatedAt: new Date()
      });

      // Notify post author
      if (postDoc.data().authorId !== req.user.uid) {
        await firestore
          .collection('users')
          .doc(postDoc.data().authorId)
          .collection('notifications')
          .add({
            type: 'post_liked',
            fromUserId: req.user.uid,
            fromUserName: req.user.name,
            message: `${req.user.name} liked your post`,
            data: { postId },
            read: false,
            createdAt: new Date()
          });
      }

      res.json({
        success: true,
        message: 'Post liked',
        liked: true
      });
    }

  } catch (error) {
    next(error);
  }
});

// Get notifications
router.get('/notifications', [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('unreadOnly').optional().isBoolean()
], async (req, res, next) => {
  try {
    const { limit = 20, unreadOnly = false } = req.query;
    
    const firestore = getFirestore();
    let query = firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('notifications')
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit));

    if (unreadOnly) {
      query = query.where('read', '==', false);
    }

    const snapshot = await query.get();
    
    const notifications = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt.toDate().toISOString()
    }));

    res.json({
      success: true,
      data: {
        notifications,
        total: notifications.length,
        unreadCount: notifications.filter(n => !n.read).length
      }
    });

  } catch (error) {
    next(error);
  }
});

// Mark notifications as read
router.post('/notifications/mark-read', [
  body('notificationIds').isArray().withMessage('Notification IDs must be an array')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { notificationIds } = req.body;
    
    const firestore = getFirestore();
    const batch = firestore.batch();

    for (const notificationId of notificationIds) {
      const notificationRef = firestore
        .collection('users')
        .doc(req.user.uid)
        .collection('notifications')
        .doc(notificationId);
      
      batch.update(notificationRef, {
        read: true,
        readAt: new Date()
      });
    }

    await batch.commit();

    res.json({
      success: true,
      message: 'Notifications marked as read',
      count: notificationIds.length
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;