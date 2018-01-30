import { OMISEGO_BASE_URL } from '../../../../omisego/config';

export const validResponse = {};
export const errorResponse = {
  error: {
    code: 'an_error',
    description: 'a_description',
  },
};
export const validEmail = 'email@example.com';
export const invalidEmail = 'invalidemail';
export const validParams = { url: OMISEGO_BASE_URL, email: validEmail };
