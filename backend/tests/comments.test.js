const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Comments API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
    global.fetch.mockReset();
  });

  describe('POST /api/posts/comment', () => {
    test('creates a comment successfully', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          truth_score: 0.80,
          verdict: 'VERIFIED',
        }),
      });

      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'c') return { properties: { id: 'comment_001', content: 'Test comment' } };
              if (key === 'ownerId') return 'owner_001';
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .post('/api/posts/comment')
        .send({
          userId: 'user_001',
          postId: 'post_001',
          content: 'Test comment',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('blocks toxic comment', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          result: { degree: 'extreme' },
        }),
      });

      const response = await request(app)
        .post('/api/posts/comment')
        .send({
          userId: 'user_001',
          postId: 'post_001',
          content: 'Extremely toxic comment',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('CONTENT_TOO_TOXIC');
    });
  });

  describe('POST /api/comments/:commentId/like', () => {
    test('likes a comment', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] })
        .mockResolvedValueOnce({
          records: [
            {
              get: (key) => {
                if (key === 'ownerId') return 'owner_001';
                if (key === 'postId') return 'post_001';
                return null;
              },
            },
          ],
        });

      const response = await request(app)
        .post('/api/comments/comment_001/like')
        .send({
          userId: 'user_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.action).toBe('liked');
    });
  });

  describe('PUT /api/comments/:commentId', () => {
    test('updates a comment', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ properties: { id: 'comment_001', content: 'Updated comment' } }),
          },
        ],
      });

      const response = await request(app)
        .put('/api/comments/comment_001')
        .send({
          userId: 'user_001',
          content: 'Updated comment',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('DELETE /api/comments/:commentId', () => {
    test('deletes a comment', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ toInt: () => 1 }),
          },
        ],
      });

      const response = await request(app)
        .delete('/api/comments/comment_001')
        .send({
          userId: 'user_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});