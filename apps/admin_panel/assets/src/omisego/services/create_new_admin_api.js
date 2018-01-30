import request from './api_service';

export default function createAdmin(params, callback) {
  const {
    email, token, password, passwordConfirm,
  } = params;
  const requestParams = {
    path: 'invite.accept',
    params: {
      email,
      token,
      password,
      password_confirm: passwordConfirm,
    },
    authenticated: false,
    callback,
  };
  return request(requestParams);
}
