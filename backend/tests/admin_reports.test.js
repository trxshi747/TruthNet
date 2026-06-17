const request = require('supertest');
const { app } = require('../index');
const { driver } = require('../index');

describe('Admin Reports API', () => {
  let session;

  beforeEach(() => {
    session = driver.session();
    session.run.mockReset();
  });

  describe('POST /api/reports', () => {
    test('creates a post report', async () => {
      session.run.mockResolvedValueOnce({
        records: [{ get: () => ({ id: 'report_001' }) }],
      });

      const response = await request(app)
        .post('/api/reports')
        .send({
          reporterId: 'user_001',
          targetId: 'post_001',
          targetType: 'Post',
          reason: 'Inappropriate content',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('creates a comment report', async () => {
      session.run.mockResolvedValueOnce({
        records: [{ get: () => ({ id: 'report_002' }) }],
      });

      const response = await request(app)
        .post('/api/reports')
        .send({
          reporterId: 'user_001',
          targetId: 'comment_001',
          targetType: 'Comment',
          reason: 'Harassment',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('rejects invalid targetType', async () => {
      const response = await request(app)
        .post('/api/reports')
        .send({
          reporterId: 'user_001',
          targetId: 'post_001',
          targetType: 'InvalidType',
          reason: 'Test',
        });

      expect(response.status).toBe(400);
      expect(response.body.message).toBe('Invalid targetType');
    });
  });

  describe('GET /api/admin/reports', () => {
    test('returns pending reports', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              const data = {
                id: 'report_001',
                reporterId: 'user_001',
                reporterName: 'john_doe',
                targetId: 'post_001',
                targetType: 'Post',
                targetContent: 'Test content',
                authorId: 'author_001',
                authorName: 'author_name',
                reason: 'Inappropriate',
                timestamp: Date.now(),
              };
              return data[key];
            },
          },
        ],
      });

      const response = await request(app)
        .get('/api/admin/reports');

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('PUT /api/admin/reports/:reportId/resolve', () => {
    test('resolves and deletes content', async () => {
      session.run
        .mockResolvedValueOnce({
          records: [
            {
              get: (key) => {
                if (key === 'targetId') return 'post_001';
                if (key === 'type') return 'Post';
                if (key === 'ownerId') return 'owner_001';
                return null;
              },
            },
          ],
        })
        .mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/admin/reports/report_001/resolve')
        .send({
          action: 'delete',
          adminId: 'admin_001',
          customReason: 'Violates community guidelines',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    test('dismisses a report', async () => {
      session.run.mockResolvedValueOnce({ records: [] });

      const response = await request(app)
        .put('/api/admin/reports/report_001/resolve')
        .send({
          action: 'dismiss',
          adminId: 'admin_001',
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });

  describe('POST /api/admin/reports/:reportId/analyze', () => {
    test('analyzes report content with AI', async () => {
      session.run.mockResolvedValueOnce({
        records: [
          {
            get: (key) => {
              if (key === 'id') return 'post_001';
              if (key === 'content') return 'Test content for analysis';
              if (key === 'type') return 'Post';
              return null;
            },
          },
        ],
      });

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          verdict: 'FAKE',
          truth_score: 0.2,
          explanation: 'Contains misinformation',
        }),
      });

      const response = await request(app)
        .post('/api/admin/reports/report_001/analyze');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
  });
});