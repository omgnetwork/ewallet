import { OMISEGO_BASE_URL } from '../../config';

export const loginValidParams = { email: 'email@example.com', password: 'password' };
export const loginInvalidParams = { email: 'email', password: 'pass' };

export const forgotPasswordValidParams = { email: 'email@example.com', url: OMISEGO_BASE_URL };
export const forgotPasswordInvalidParams = { email: 'email', url: '' };
