module.exports = {
  verbose: true,
  rootDir: '../',
  testMatch: ['**/*.test.js?(x)'],
  setupFiles: ['./config/jest.setup.js'],
  globals: {
    __DEV__: true,
    CONFIG: { BACKEND_API_URL: null }
  },
  testURL: 'http://localhost/',
  moduleNameMapper: {
    '.+\\.(css|styl|less|sass|scss|png|jpg|ttf|woff|woff2)$': 'identity-obj-proxy'
  }
}
