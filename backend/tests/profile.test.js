const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Profile API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
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

  describe('GET /api/users/:userId/posts', () => {
    test('returns user posts', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'author') return 'john_doe';
              if (key === 'post') return { properties: { id: 'post_001', content: 'Test post' } };
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/users/user_001/posts');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('GET /api/users/:userId/archive', () => {
    test('returns archived posts', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'author') return 'john_doe';
              if (key === 'post') return { properties: { id: 'post_001', content: 'Archived post', isDeleted: true } };
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/users/user_001/archive');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });
});