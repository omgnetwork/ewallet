import buildURL from '../helpers/urlHelper';

export const loginValidParams = { email: 'email@example.com', password: 'password' };
export const loginInvalidParams = { email: 'email', password: 'pass' };

const serverErrorResponse = {
  code: 'server:internal_server_error',
  description: 'Something went wrong on the server',
};

function successBody(data) {
  return ({
    version: '1',
    success: true,
    data,
  });
}

function errorBody(data) {
  return ({
    version: '1',
    success: false,
    data,
  });
}

export function loginStub(params) {
  return (
    JSON.stringify(params) === JSON.stringify(loginValidParams) ?
      {
        url: buildURL('login'),
        response: successBody({
          object: 'authentication_token',
          authentication_token: 'azJRj09l7jvR8KhTqUs3',
          user_id: '12345678-1234-1234-1234-123456789012',
        }),
      } : {
        url: buildURL('login'),
        response: errorBody(serverErrorResponse),
      });
}
