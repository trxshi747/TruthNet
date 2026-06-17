const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Admin Sanctions API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('PUT /api/admin/users/:userId/suspend', () => {
    test('suspends a user', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/admin/users/user_001/suspend')
        .send({
          reason: 'Violating community guidelines',
          durationDays: 7,
          adminId: 'admin_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('PUT /api/admin/users/:userId/ban', () => {
    test('bans a user permanently', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] })
        .mockResolvedValueOnce({ records: [] })
        .mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/admin/users/user_001/ban')
        .send({
          reason: 'Permanent ban',
          adminId: 'admin_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('requires a reason', async () => {
      const response = await request(app)
        .put('/api/admin/users/user_001/ban')
        .send({
          adminId: 'admin_001',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('Reason is required');
    });
  });

  describe('PUT /api/admin/sanctions/:sanctionId/revoke', () => {
    test('revokes a sanction', async () => {
      session.run
        .mockResolvedValueOnce({
          records: [
            {
              get: (key) => {
                if (key === 'userId') return 'user_001';
                if (key === 'type') return 'SUSPENSION';
                return null;
              },
            },
          ],
        })
        .mockResolvedValueOnce({ records: [] })
        .mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/admin/sanctions/sanction_001/revoke')
        .send({
          adminId: 'admin_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('PUT /api/admin/users/:userId/activate', () => {
    test('activates a user', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] })
        .mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/admin/users/user_001/activate')
        .send({
          adminId: 'admin_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /api/admin/sanctions/active', () => {
    test('returns active sanctions', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'user_001', firstName: 'John', lastName: 'Doe', email: 'john@test.com', username: 'john_doe' } };
              if (key === 's') return { properties: { id: 'sanction_001', type: 'SUSPENSION', reason: 'Violation', startDate: Date.now(), endDate: Date.now() + 604800000, status: 'ACTIVE', createdBy: 'admin_001' } };
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/admin/sanctions/active');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });
});