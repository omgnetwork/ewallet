import { formatEmailLink } from '../../../../helpers/urlFormatter';
import { INVITATION } from '../../../authenticated/setting/Setting';

export const validResponse = {};
export const errorResponse = {
  error: {
    code: 'an_error',
    description: 'a_description',
  },
};
export const validEmail = 'email@example.com';
export const invalidEmail = 'invalidemail';
export const validParams = { redirect_url: formatEmailLink(INVITATION), email: validEmail };
