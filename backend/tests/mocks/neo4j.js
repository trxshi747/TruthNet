const session = {
    run: jest.fn(),
    close: jest.fn()
};

module.exports = {
    session,
    driver: {
        session: () => session
    }
};