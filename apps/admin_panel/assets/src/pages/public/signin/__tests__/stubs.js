export const validResponse = {
  authentication_token: 'a_valid_token',
  user_id: 'a_valid_user_id',
};
export const errorResponse = {
  error: {
    code: 'user:invalid_login_credentials',
    description: 'There is no user corresponding to the provided login credentials',
  },
};
export const validParams = { email: 'email@example.com', password: 'password' };
export const validEmail = 'email@example.com';
export const validPassword = 'password';
export const invalidEmail = 'invalid';
export const invalidPassword = 'in';
