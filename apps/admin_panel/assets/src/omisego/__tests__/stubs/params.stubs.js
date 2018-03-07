import { ADMIN_API_BASE_URL } from '../../config';

export const loginValidParams = { email: 'email@example.com', password: 'password' };
export const loginInvalidParams = { email: 'email', password: 'pass' };

export const resetPasswordValidParams = { email: 'email@example.com', url: ADMIN_API_BASE_URL };
export const resetPasswordInvalidParams = { email: 'email', url: '' };
