const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

// Mock bcrypt
jest.mock('bcryptjs', () => ({
  hash: jest.fn(() => Promise.resolve('hashed_password')),
  compare: jest.fn(() => Promise.resolve(true)),
}));

describe('Admin Moderators API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('GET /api/admin/moderators', () => {
    test('returns list of moderators', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'mod_001', firstName: 'Mod', lastName: 'User', username: 'mod_user', email: 'mod@test.com', status: 'ACTIVE' } };
              if (key === 'role') return 'Moderator';
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/admin/moderators');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('POST /api/admin/moderators', () => {
    test('creates a new moderator', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] }) // Check existing
        .mockResolvedValueOnce({ records: [] }) // Create moderator
        .mockResolvedValueOnce({ records: [{}] }); // Return

      const response = await request(app)
        .post('/api/admin/moderators')
        .send({
          firstName: 'New',
          lastName: 'Moderator',
          username: 'new_mod',
          email: 'new_mod@test.com',
          password: 'Password123',
          status: 'ACTIVE',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('rejects invalid username', async () => {
      const response = await request(app)
        .post('/api/admin/moderators')
        .send({
          firstName: 'New',
          lastName: 'Moderator',
          username: 'new@mod',
          email: 'new_mod@test.com',
          password: 'Password123',
          status: 'ACTIVE',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('USERNAME_INVALID_SYMBOLS_DETECTED');
    });
  });

  describe('PUT /api/admin/moderators/:id', () => {
    test('updates a moderator', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] })
        .mockResolvedValueOnce({ records: [] }) // Update role if needed
        .mockResolvedValueOnce({
          records: [
            {
              get: (key) => {
                if (key === 'u') return { properties: { id: 'mod_001', firstName: 'Updated', lastName: 'Moderator', username: 'updated_mod', email: 'updated@test.com', status: 'ACTIVE' } };
                if (key === 'role') return 'Moderator';
                return null;
              },
            },
          ],
        });

      const response = await request(app)
        .put('/api/admin/moderators/mod_001')
        .send({
          firstName: 'Updated',
          lastName: 'Moderator',
          username: 'updated_mod',
          email: 'updated@test.com',
          status: 'ACTIVE',
          role: 'Moderator',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('DELETE /api/admin/moderators/:id', () => {
    test('deletes a moderator', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .delete('/api/admin/moderators/mod_001');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});