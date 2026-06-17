const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

// Mock AI service
jest.mock('node-fetch');

describe('Posts API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
    global.fetch.mockReset();
  });

  describe('POST /api/posts', () => {
    test('creates a post successfully', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          truth_score: 0.85,
          verdict: 'VERIFIED',
          explanation: 'Content verified',
          sources: ['Source 1'],
        }),
      });

      session.run
        .mockResolvedValueOnce({
          records: [
            {
              get: () => ({ properties: { id: 'post_001', content: 'Test content' } }),
            },
          ],
        });

      const response = await request(app)
        .post('/api/posts')
        .field('userId', 'user_001')
        .field('content', 'Test content')
        .field('isPublic', 'true');

      expect(response.status).toBe(200);
      expect(response.body.id).toBeDefined();
    });

    test('blocks toxic content', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          result: { degree: 'extreme' },
        }),
      });

      const response = await request(app)
        .post('/api/posts')
        .field('userId', 'user_001')
        .field('content', 'Extremely toxic content')
        .field('isPublic', 'true');

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('CONTENT_TOO_TOXIC');
    });
  });

  describe('GET /api/feed', () => {
    test('returns feed for user', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'author') return 'john_doe';
              if (key === 'authorId') return 'user_001';
              if (key === 'post') return { properties: { id: 'post_001', content: 'Test' } };
              if (key === 'likeCount') return { toInt: () => 10 };
              if (key === 'commentCount') return { toInt: () => 5 };
              if (key === 'shareCount') return { toInt: () => 2 };
              if (key === 'isSaved') return false;
              if (key === 'isLiked') return true;
              return null;
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/feed?userId=user_001');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('POST /api/posts/like', () => {
    test('likes a post', async () => {
      session.run
        .mockResolvedValueOnce({ records: [] }) // Check existing
        .mockResolvedValueOnce({
          records: [{ get: () => 'owner_001' }],
        });

      const response = await request(app)
        .post('/api/posts/like')
        .send({
          userId: 'user_001',
          postId: 'post_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.action).toBe('liked');
    });

    test('unlikes a post', async () => {
      session.run
        .mockResolvedValueOnce({ records: [{}] }) // Check existing
        .mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .post('/api/posts/like')
        .send({
          userId: 'user_001',
          postId: 'post_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.action).toBe('unliked');
    });
  });

  describe('PUT /api/posts/:postId', () => {
    test('updates a post within edit window', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ properties: { id: 'post_001', content: 'Updated content' } }),
          },
        ],
      });

      const response = await request(app)
        .put('/api/posts/post_001')
        .send({
          userId: 'user_001',
          content: 'Updated content',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('DELETE /api/posts/:postId/permanent', () => {
    test('deletes a post permanently', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: () => ({ toInt: () => 1 }),
          },
        ],
      });

      const response = await request(app)
        .delete('/api/posts/post_001/permanent')
        .send({
          userId: 'user_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});