import request from './api_service';

export function login(params, callback) {
  const requestParams = {
    path: 'login',
    params: JSON.stringify(params),
    authenticated: false,
    callback,
  };
  return request(requestParams);
}

export function logout(params, callback) {
  const requestParams = {
    path: 'logout',
    params: null,
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function resetPassword(params, callback) {
  const {
    email, url,
  } = params;
  const requestParams = {
    path: 'password.reset',
    params: JSON.stringify({ email, redirect_url: url }),
    authenticated: false,
    callback,
  };
  return request(requestParams);
}

export function updatePassword(params, callback) {
  const {
    resetToken, password, passwordConfirmation, email,
  } = params;
  const requestParams = {
    path: 'password.update',
    params: JSON.stringify({
      email, token: resetToken, password, password_confirmation: passwordConfirmation,
    }),
    authenticated: false,
    callback,
  };
  return request(requestParams);
}
