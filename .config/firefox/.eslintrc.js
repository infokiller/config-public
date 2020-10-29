/* global module */

module.exports = {
  env: {
    es2017: true,
    browser: true,
    webextensions: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 11,
  },
  rules: {
    'require-jsdoc': 0,
  },
};
