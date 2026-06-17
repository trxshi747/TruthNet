const bcrypt = require('bcryptjs');

jest.mock('bcryptjs');

describe('Init Admin', () => {
  test('bcrypt hashes password', async () => {
    bcrypt.hash.mockResolvedValue('hashed_password');

    const result = await bcrypt.hash('Admin123!', 10);

    expect(result).toBe('hashed_password');
    expect(bcrypt.hash).toHaveBeenCalledWith('Admin123!', 10);
  });

  test('bcrypt compares passwords', async () => {
    bcrypt.compare.mockResolvedValue(true);

    const result = await bcrypt.compare('Password123', 'hashed_password');

    expect(result).toBe(true);
    expect(bcrypt.compare).toHaveBeenCalledWith('Password123', 'hashed_password');
  });
});