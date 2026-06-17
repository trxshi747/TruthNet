const request = require('supertest');
const { app } = require('../index');

describe('AI Service API', () => {
  beforeEach(() => {
    global.fetch.mockReset();
  });

  describe('POST /api/ai/analyze/comment', () => {
    test('analyzes a comment', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          result: {
            sentiment: { label: 'positive', confidence: 0.95 },
            toxicity: { is_toxic: false, toxic_score: 0.1 },
          },
        }),
      });

      const response = await request(app)
        .post('/api/ai/analyze/comment')
        .send({
          text: 'Great post!',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('POST /api/ai/verify', () => {
    test('verifies content', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          truth_score: 0.85,
          verdict: 'VERIFIED',
          explanation: 'Content is accurate',
        }),
      });

      const response = await request(app)
        .post('/api/ai/verify')
        .send({
          text: 'The Earth is round',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('GET /api/ai/health', () => {
    test('returns AI service health', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ status: 'healthy' }),
      });

      const response = await request(app)
        .get('/api/ai/health');

      expect(response.status).toBe(200);
      expect(response.body.bridge).toBe('ok');
    });
  });
});