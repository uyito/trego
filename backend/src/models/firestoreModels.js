const { getFirestore } = require('../config/firebase');
const logger = require('../utils/logger');

class FirestoreModel {
  constructor(collectionName) {
    this.db = getFirestore();
    this.collection = this.db.collection(collectionName);
    this.collectionName = collectionName;
  }

  async create(data) {
    try {
      const docRef = await this.collection.add({
        ...data,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      logger.info(`Document created in ${this.collectionName}: ${docRef.id}`);
      
      const doc = await docRef.get();
      return { id: doc.id, ...doc.data() };
    } catch (error) {
      logger.error(`Error creating document in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async findById(id) {
    try {
      const doc = await this.collection.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return { id: doc.id, ...doc.data() };
    } catch (error) {
      logger.error(`Error finding document by ID in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async findOne(filters = {}) {
    try {
      let query = this.collection;
      
      Object.entries(filters).forEach(([field, value]) => {
        query = query.where(field, '==', value);
      });
      
      const snapshot = await query.limit(1).get();
      
      if (snapshot.empty) {
        return null;
      }
      
      const doc = snapshot.docs[0];
      return { id: doc.id, ...doc.data() };
    } catch (error) {
      logger.error(`Error finding document in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async find(filters = {}, options = {}) {
    try {
      let query = this.collection;
      
      Object.entries(filters).forEach(([field, value]) => {
        if (typeof value === 'object' && value !== null) {
          // Handle complex queries like { $gte: value }
          Object.entries(value).forEach(([operator, operatorValue]) => {
            switch (operator) {
              case '$gte':
                query = query.where(field, '>=', operatorValue);
                break;
              case '$lte':
                query = query.where(field, '<=', operatorValue);
                break;
              case '$gt':
                query = query.where(field, '>', operatorValue);
                break;
              case '$lt':
                query = query.where(field, '<', operatorValue);
                break;
              case '$in':
                query = query.where(field, 'in', operatorValue);
                break;
              case '$ne':
                query = query.where(field, '!=', operatorValue);
                break;
            }
          });
        } else {
          query = query.where(field, '==', value);
        }
      });
      
      if (options.orderBy) {
        const [field, direction = 'asc'] = options.orderBy.split(' ');
        query = query.orderBy(field, direction);
      }
      
      if (options.limit) {
        query = query.limit(options.limit);
      }
      
      const snapshot = await query.get();
      
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      logger.error(`Error finding documents in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async updateById(id, data) {
    try {
      await this.collection.doc(id).update({
        ...data,
        updatedAt: new Date()
      });
      
      logger.info(`Document updated in ${this.collectionName}: ${id}`);
      
      return await this.findById(id);
    } catch (error) {
      logger.error(`Error updating document in ${this.collectionName}:`, error);
      throw error;
    }
  }

  async deleteById(id) {
    try {
      await this.collection.doc(id).delete();
      logger.info(`Document deleted from ${this.collectionName}: ${id}`);
      return true;
    } catch (error) {
      logger.error(`Error deleting document from ${this.collectionName}:`, error);
      throw error;
    }
  }

  async count(filters = {}) {
    try {
      let query = this.collection;
      
      Object.entries(filters).forEach(([field, value]) => {
        query = query.where(field, '==', value);
      });
      
      const snapshot = await query.get();
      return snapshot.size;
    } catch (error) {
      logger.error(`Error counting documents in ${this.collectionName}:`, error);
      throw error;
    }
  }
}

// Define collection models
const User = new FirestoreModel('users');
const UserProfile = new FirestoreModel('userProfiles');
const Workout = new FirestoreModel('workouts');
const Exercise = new FirestoreModel('exercises');
const WorkoutPlan = new FirestoreModel('workoutPlans');
const Recipe = new FirestoreModel('recipes');
const Nutrition = new FirestoreModel('nutrition');
const Achievement = new FirestoreModel('achievements');
const UserAchievement = new FirestoreModel('userAchievements');
const DailyLog = new FirestoreModel('dailyLogs');
const WeeklyReport = new FirestoreModel('weeklyReports');
const SocialPost = new FirestoreModel('socialPosts');
const TdeeCalculation = new FirestoreModel('tdeeCalculations');

module.exports = {
  FirestoreModel,
  User,
  UserProfile,
  Workout,
  Exercise,
  WorkoutPlan,
  Recipe,
  Nutrition,
  Achievement,
  UserAchievement,
  DailyLog,
  WeeklyReport,
  SocialPost,
  TdeeCalculation
};