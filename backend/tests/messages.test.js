const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Messages API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('POST /api/messages', () => {
    test('sends a message', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ properties: { id: 'msg_001', content: 'Hello', createdAt: Date.now() } }),
          },
        ],
      });

      const response = await request(app)
        .post('/api/messages')
        .send({
          senderId: 'user_001',
          receiverId: 'user_002',
          content: 'Hello',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /api/messages/history/:userId/:otherId', () => {
    test('returns message history', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              const data = {
                id: 'msg_001',
                content: 'Hello',
                createdAt: { toNumber: () => Date.now() },
                senderId: 'user_001',
              };
              return data[key];
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/messages/history/user_001/user_002');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('GET /api/messages/conversations/:userId', () => {
    test('returns conversations list', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              const data = {
                id: 'user_002',
                username: 'jane_doe',
                lastMessage: 'Hello!',
                lastMessageAt: { toNumber: () => Date.now() },
              };
              return data[key];
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/messages/conversations/user_001');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });
});