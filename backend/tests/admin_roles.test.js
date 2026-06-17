const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Admin Roles API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('GET /api/admin/roles', () => {
    test('returns all roles', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'r') return { properties: { id: 'role_001', name: 'Admin', description: 'Administrator role' } };
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/admin/roles');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('POST /api/admin/roles', () => {
    test('creates a new role', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .post('/api/admin/roles')
        .send({
          name: 'Guest',
          description: 'Guest role',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('PUT /api/admin/roles/:id', () => {
    test('updates a role', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ properties: { id: 'role_001', name: 'Updated', description: 'Updated description' } }),
          },
        ],
      });

      const response = await request(app)
        .put('/api/admin/roles/role_001')
        .send({
          name: 'Updated',
          description: 'Updated description',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('DELETE /api/admin/roles/:id', () => {
    test('deletes a role not in use', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'userCount') return { toInt: () => 0 };
              if (key === 'roleName') return 'Guest';
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .delete('/api/admin/roles/role_001');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('prevents deletion of role in use', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'userCount') return { toInt: () => 5 };
              if (key === 'roleName') return 'Admin';
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .delete('/api/admin/roles/role_001');

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('ROLE_IN_USE');
    });
  });
});