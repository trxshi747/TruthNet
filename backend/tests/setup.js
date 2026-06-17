// tests/setup.js
const { driver } = require('../index');

// Mock Neo4j driver
jest.mock('neo4j-driver', () => {
  const session = {
    run: jest.fn(),
    close: jest.fn(),
  };
  return {
    driver: jest.fn(() => ({
      session: jest.fn(() => session),
      close: jest.fn(),
    })),
    auth: {
      basic: jest.fn(() => ({})),
    },
  };
});

// Mock fetch for AI service
global.fetch = jest.fn();

// Clean up after each test
afterEach(async () => {
  jest.clearAllMocks();
});

// Close driver after all tests
afterAll(async () => {
  try {
    await driver?.close();
  } catch (e) {
    // Ignore
  }
});

jest.setTimeout(10000);