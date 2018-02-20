import request from './api_service';

export function login(params) {
  const requestParams = {
    path: 'login',
    params: JSON.stringify(params),
    authenticated: false,
  };
  return request(requestParams);
}

export function logout() {
  const requestParams = {
    path: 'logout',
    params: null,
    authenticated: true,
  };
  return request(requestParams);
}

export function resetPassword(params) {
  const {
    email, url,
  } = params;
  const requestParams = {
    path: 'password.reset',
    params: JSON.stringify({ email, redirect_url: url }),
    authenticated: false,
  };
  return request(requestParams);
}

export function updatePassword(params) {
  const {
    resetToken, password, passwordConfirmation, email,
  } = params;
  const requestParams = {
    path: 'password.update',
    params: JSON.stringify({
      email, token: resetToken, password, password_confirmation: passwordConfirmation,
    }),
    authenticated: false,
  };
  return request(requestParams);
}
