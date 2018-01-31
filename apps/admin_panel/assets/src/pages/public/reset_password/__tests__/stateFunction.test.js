import {
  getEmailValidationState,
  onInputChange,
  onSubmit,
} from '../stateFunctions';
import { validEmail, invalidEmail } from './stubs';

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

describe('onInputChange', () => {
  test('return updated state with email', () => {
    const startState = {
      didModifyEmail: false,
    };
    expect(onInputChange({ id: 'email', value: 'email@example.com' }, startState))
      .toEqual({ email: 'email@example.com', didModifyEmail: true });
  });
});

test('toggle submitted to true when submitting', () => {
  expect(onSubmit()).toEqual({ submitted: true });
});
