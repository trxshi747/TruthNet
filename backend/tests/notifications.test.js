const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Notifications API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('GET /api/notifications/:userId', () => {
    test('returns notifications for user', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              const data = {
                id: 'notif_001',
                type: 'follow',
                text: 'John Doe followed you',
                postId: null,
                commentId: null,
                isRead: false,
                createdAt: { toNumber: () => Date.now() },
                actorUsername: 'john_doe',
                actorAvatar: null,
                actorId: 'user_001',
              };
              return data[key];
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/notifications/user_001');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('PUT /api/notifications/:notifId/read', () => {
    test('marks notification as read', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/notifications/notif_001/read');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});