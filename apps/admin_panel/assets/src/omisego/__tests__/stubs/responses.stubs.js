export function successBody(data) {
  return ({
    version: '1',
    success: true,
    data,
  });
}

export function errorBody(data) {
  return ({
    version: '1',
    success: false,
    data,
  });
}

export const serverErrorResponse = errorBody({
  code: 'server:internal_server_error',
  description: 'Something went wrong on the server',
});

export const loginSuccessResponse = successBody({
  object: 'authentication_token',
  authentication_token: 'azJRj09l7jvR8KhTqUs3',
  user_id: '12345678-1234-1234-1234-123456789012',
});

export const forgotPasswordSuccessResponse = successBody({});
