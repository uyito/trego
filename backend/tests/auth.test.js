const request = require('supertest');
const app = require('../src/app');

describe('Authentication Endpoints', () => {
  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'TestPassword123',
        name: 'Test User',
        age: 25,
        gender: 'male'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body).toMatchObject({
        success: true,
        message: 'User registered successfully',
        token: expect.any(String),
        user: {
          email: userData.email,
          name: userData.name,
          subscription: 'free'
        }
      });
    });

    it('should reject registration with invalid email', async () => {
      const userData = {
        email: 'invalid-email',
        password: 'TestPassword123',
        name: 'Test User'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body).toMatchObject({
        error: 'Validation failed'
      });
    });

    it('should reject registration with weak password', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'weak',
        name: 'Test User'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body.error).toBe('Validation failed');
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Register a test user
      await request(app)
        .post('/api/auth/register')
        .send({
          email: 'login-test@example.com',
          password: 'TestPassword123',
          name: 'Login Test User'
        });
    });

    it('should login successfully with correct credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'login-test@example.com',
          password: 'TestPassword123'
        })
        .expect(200);

      expect(response.body).toMatchObject({
        success: true,
        message: 'Login successful',
        token: expect.any(String),
        user: {
          email: 'login-test@example.com'
        }
      });
    });

    it('should reject login with incorrect password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'login-test@example.com',
          password: 'WrongPassword'
        })
        .expect(401);

      expect(response.body).toMatchObject({
        error: 'Authentication failed'
      });
    });

    it('should reject login with non-existent email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'TestPassword123'
        })
        .expect(401);

      expect(response.body).toMatchObject({
        error: 'Authentication failed'
      });
    });
  });

  describe('GET /api/auth/profile', () => {
    let authToken;

    beforeEach(async () => {
      // Register and login to get auth token
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'profile-test@example.com',
          password: 'TestPassword123',
          name: 'Profile Test User',
          age: 30
        });

      authToken = registerResponse.body.token;
    });

    it('should get user profile with valid token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toMatchObject({
        success: true,
        user: {
          email: 'profile-test@example.com',
          name: 'Profile Test User',
          age: 30
        }
      });
    });

    it('should reject request without token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .expect(401);

      expect(response.body).toMatchObject({
        error: 'Access denied'
      });
    });

    it('should reject request with invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(response.body).toMatchObject({
        error: 'Access denied'
      });
    });
  });

  describe('PUT /api/auth/profile', () => {
    let authToken;

    beforeEach(async () => {
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'update-test@example.com',
          password: 'TestPassword123',
          name: 'Update Test User'
        });

      authToken = registerResponse.body.token;
    });

    it('should update user profile successfully', async () => {
      const updateData = {
        name: 'Updated Name',
        age: 35,
        'preferences.units': 'imperial'
      };

      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body).toMatchObject({
        success: true,
        message: 'Profile updated successfully'
      });
    });

    it('should reject update with invalid data', async () => {
      const updateData = {
        age: 'invalid-age'
      };

      const response = await request(app)
        .put('/api/auth/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(400);

      expect(response.body).toMatchObject({
        error: 'Validation failed'
      });
    });
  });
});