const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

// Mock bcrypt
jest.mock('bcryptjs', () => ({
  hash: jest.fn(() => Promise.resolve('hashed_password')),
  compare: jest.fn(() => Promise.resolve(true)),
}));

describe('Authentication API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('POST /api/auth/register', () => {
    test('rejects weak password (less than 8 chars)', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          password: '123',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('PASSWORD_TOO_WEAK_OR_TOO_SHORT');
    });

    test('rejects password without letters', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          password: '12345678',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('PASSWORD_TOO_WEAK_OR_TOO_SHORT');
    });

    test('rejects password without numbers', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          password: 'abcdefgh',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('PASSWORD_TOO_WEAK_OR_TOO_SHORT');
    });

    test('rejects invalid username (special chars)', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          username: 'john@123',
          password: 'Password123',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('USERNAME_INVALID_SYMBOLS_DETECTED');
    });

    test('rejects existing email', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => (key === 'email' ? 'john@test.com' : null),
          },
        ],
      });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          password: 'Password123',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('EMAIL_EXISTS');
    });

    test('registers successfully with valid data', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] }) // Check existing
        .mockResolvedValueOnce({
          records: [
            {
              get: (key) => {
                if (key === 'u') return { properties: { id: 'uuid', email: 'john@test.com' } };
                if (key === 'role') return 'Member';
                return null;
              },
            },
          ],
        });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          password: 'Password123',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('POST /api/auth/login', () => {
    test('returns 401 for invalid credentials', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'john@test.com',
          password: 'WrongPassword123',
        });

      expect(response.status).toBe(401);
      expect(response.body.message).toBe('USER_NOT_FOUND');
    });

    test('returns 403 for suspended account', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'uuid', status: 'SUSPENDED' } };
              if (key === 'role') return 'Member';
              if (key === 'sanctions') return [{ properties: { endDate: '2025-12-31' } }];
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'john@test.com',
          password: 'Password123',
        });

      expect(response.status).toBe(403);
      expect(response.body.message).toBe('ACCOUNT_SUSPENDED');
    });

    test('returns 403 for banned account', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'u') return { properties: { id: 'uuid', status: 'BANNED' } };
              if (key === 'role') return 'Member';
              if (key === 'sanctions') return [];
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'john@test.com',
          password: 'Password123',
        });

      expect(response.status).toBe(403);
      expect(response.body.message).toBe('ACCOUNT_BANNED');
    });
  });

  describe('PUT /api/auth/update-password', () => {
    test('rejects weak new password', async () => {
      const response = await request(app)
        .put('/api/auth/update-password')
        .send({
          userId: 'uuid',
          oldPassword: 'OldPassword123',
          newPassword: '123',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('PASSWORD_TOO_WEAK_OR_TOO_SHORT');
    });

    test('rejects incorrect old password', async () => {
      const bcrypt = require('bcryptjs');
      bcrypt.compare.mockResolvedValueOnce(false);

      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ properties: { id: 'uuid', password: 'hashed' } }),
          },
        ],
      });

      const response = await request(app)
        .put('/api/auth/update-password')
        .send({
          userId: 'uuid',
          oldPassword: 'WrongPassword123',
          newPassword: 'NewPassword123',
        });

      expect(response.status).toBe(401);
      expect(response.body.message).toBe('INCORRECT_OLD_PASSWORD');
    });
  });

  describe('PUT /api/auth/update-email', () => {
    test('rejects existing email', async () => {
      session.run.mockResolvedValueOnce({
        records: [{ get: () => 'existing@test.com' }],
      });

      const response = await request(app)
        .put('/api/auth/update-email')
        .send({
          userId: 'uuid',
          newEmail: 'existing@test.com',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('EMAIL_ALREADY_IN_USE');
    });
  });
});