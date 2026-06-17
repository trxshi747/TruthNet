const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Users API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('POST /api/users/follow', () => {
    test('follows a user', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] }) // Check existing
        .mockResolvedValueOnce({ records: [] }) // Update following count
        .mockResolvedValueOnce({ records: [] }) // Update follower count
        .mockResolvedValueOnce({ records: [] }); // Notification

      const response = await request(app)
        .post('/api/users/follow')
        .send({
          userId: 'user_001',
          targetId: 'user_002',
        });

      expect(response.status).toBe(200);
      expect(response.body.action).toBe('followed');
    });

    test('unfollows a user', async () => {
      session.run
        .mockResolvedValueOnce({ records: [{}] }) // Check existing
        .mockResolvedValueOnce({ records: [] }) // Delete follow
        .mockResolvedValueOnce({ records: [] }) // Update following count
        .mockResolvedValueOnce({ records: [] }); // Update follower count

      const response = await request(app)
        .post('/api/users/follow')
        .send({
          userId: 'user_001',
          targetId: 'user_002',
        });

      expect(response.status).toBe(200);
      expect(response.body.action).toBe('unfollowed');
    });
  });

  describe('GET /api/users/search', () => {
    test('searches users by username', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'name') return 'john_doe';
              if (key === 'id') return 'user_001';
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/users/search?query=john&excludeId=user_002');

      expect(response.status).toBe(200);
      expect(response.body.length).toBeGreaterThan(0);
    });
  });

  describe('GET /api/users/:userId/profile', () => {
    test('returns profile for admin user', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'admin_001', firstName: 'Admin' } };
              if (key === 'role') return 'Admin';
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/users/admin_001/profile');

      expect(response.status).toBe(200);
      expect(response.body.role).toBe('Admin');
    });

    test('returns profile for standard user', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'user_001', firstName: 'John' } };
              if (key === 'profile') return { properties: { bio: 'Test bio', followerCount: 10, followingCount: 5 } };
              if (key === 'postCount') return { toInt: () => 20 };
              if (key === 'followerCount') return { toInt: () => 10 };
              if (key === 'followingCount') return { toInt: () => 5 };
              if (key === 'isFollowing') return false;
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/users/user_001/profile?currentUserId=user_002');

      expect(response.status).toBe(200);
      expect(response.body.followerCount).toBe(10);
    });
  });

  describe('PUT /api/users/:userId/profile', () => {
    test('updates user profile', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'user_001', firstName: 'John' } };
              if (key === 'p') return { properties: { bio: 'Updated bio' } };
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .put('/api/users/user_001/profile')
        .send({
          firstName: 'John',
          lastName: 'Smith',
          bio: 'Updated bio',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});