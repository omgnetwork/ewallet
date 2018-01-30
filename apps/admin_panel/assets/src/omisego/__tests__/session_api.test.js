import fetchMock from 'fetch-mock';

import { login, forgotPassword } from '../services/session_api';
import {
  loginValidParams,
  loginInvalidParams,
  forgotPasswordValidParams,
  forgotPasswordInvalidParams,
} from './stubs/params.stubs';
import {
  loginStub,
  forgotPasswordStub,
} from './stubs/stubs';

describe('login api', () => {
  afterEach(() => {
    fetchMock.reset();
    fetchMock.restore();
  });

  test('callback success with valid params', () => {
    const mock = loginStub(loginValidParams);
    fetchMock.postOnce(mock.url, mock.response);
    login(loginValidParams, (error, result) => {
      expect(error).toBeNull();
      expect(result).toEqual(mock.response.data);
    });
  });

  test('callback error with invalid params', () => {
    const mock = loginStub(loginInvalidParams);
    fetchMock.postOnce(mock.url, mock.response);
    login(loginInvalidParams, (error, result) => {
      expect(result).toBeNull();
      expect(error).toEqual(mock.response.data);
    });
  });
});

describe('forgot password api', () => {
  afterEach(() => {
    fetchMock.reset();
    fetchMock.restore();
  });

  test('callback success with valid params', () => {
    const mock = forgotPasswordStub(forgotPasswordValidParams);
    fetchMock.postOnce(mock.url, mock.response);
    forgotPassword(forgotPasswordValidParams, (error, result) => {
      expect(error).toBeNull();
      expect(result).toEqual(mock.response.data);
    });
  });

  test('callback error with invalid params', () => {
    const mock = forgotPasswordStub(forgotPasswordInvalidParams);
    fetchMock.postOnce(mock.url, mock.response);
    forgotPassword(forgotPasswordInvalidParams, (error, result) => {
      expect(result).toBeNull();
      expect(error).toEqual(mock.response.data);
    });
  });
});
