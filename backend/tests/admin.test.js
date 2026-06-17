const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Admin API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('GET /api/admin/users', () => {
    test('returns list of member users', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              const data = {
                id: 'user_001',
                firstName: 'John',
                lastName: 'Doe',
                username: 'john_doe',
                email: 'john@test.com',
                status: 'ACTIVE',
                registrationDate: Date.now(),
                role: 'Member',
                bio: 'Test bio',
                avatar: null,
                sanctionId: null,
                sanctionType: null,
                sanctionReason: null,
                sanctionEndDate: null,
              };
              return data[key];
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/admin/users');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('GET /api/admin/dashboard', () => {
    test('returns dashboard metrics', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              const data = { users: 100, posts: 500, comments: 1000, reports: 50, pendingReports: 10, resolvedReports: 40 };
              return { toInt: () => data[key] };
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/admin/dashboard');

      expect(response.status).toBe(200);
      expect(response.body.users).toBe(100);
      expect(response.body.posts).toBe(500);
    });
  });

  describe('DELETE /api/admin/users/:userId', () => {
    test('deletes a user permanently', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .delete('/api/admin/users/user_001');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});