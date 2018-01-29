import {
  getEmailValidationState,
  getPasswordValidationState,
  onInputChange,
  onSubmit,
} from '../stateFunctions';
import { validEmail, validPassword, invalidEmail, invalidPassword } from './stubs';

describe('getEmailValidationState', () => {
  test('return null validation state if not submitted, valid email and has been modified', () => {
    const startState = {
      didModifyEmail: true,
      submitted: false,
      email: validEmail,
    };
    expect(getEmailValidationState(startState)).toBeNull();
  });
  test('return null validation state if not submitted, invalid email and has not been modified', () => {
    const startState = {
      didModifyEmail: false,
      submitted: false,
      email: invalidEmail,
    };
    expect(getEmailValidationState(startState)).toBeNull();
  });
  test('return error validation state, invalid email and has been modified', () => {
    const startState = {
      didModifyEmail: true,
      email: invalidEmail,
    };
    expect(getEmailValidationState(startState)).toBe('error');
  });
});

describe('getPasswordValidationState', () => {
  test('return null validation state if not submitted, valid password and has been modified', () => {
    const startState = {
      didModifyPassword: true,
      submitted: false,
      password: validPassword,
    };
    expect(getPasswordValidationState(startState)).toBeNull();
  });
  test('return null validation state if not submitted, invalid password and has not been modified', () => {
    const startState = {
      didModifyPassword: false,
      submitted: false,
      password: invalidPassword,
    };
    expect(getPasswordValidationState(startState)).toBeNull();
  });
  test('return error validation state, invalid password and has been modified', () => {
    const startState = {
      didModifyPassword: true,
      password: invalidPassword,
    };
    expect(getPasswordValidationState(startState)).toBe('error');
  });
});

describe('onInputChange', () => {
  test('return updated state with email', () => {
    const startState = {
      didModifyEmail: false,
      didModifyPassword: false,
    };
    expect(onInputChange({ id: 'email', value: 'email@example.com' }, startState))
      .toEqual({ email: 'email@example.com', didModifyEmail: true, didModifyPassword: false });
  });

  test('return updated state with password', () => {
    const startState = {
      didModifyEmail: false,
      didModifyPassword: false,
    };
    expect(onInputChange({ id: 'password', value: 'password@example.com' }, startState))
      .toEqual({ password: 'password@example.com', didModifyEmail: false, didModifyPassword: true });
  });
});

test('toggle submitted to true when submitting', () => {
  expect(onSubmit()).toEqual({ submitted: true });
});
