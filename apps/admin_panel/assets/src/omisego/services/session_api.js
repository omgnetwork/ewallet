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

export function logout(callback) {
  const requestParams = {
    path: 'logout',
    params: null,
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function forgotPassword(params, callback) {
  callback(null, {});
  // const requestParams = {
  //   path: 'forgot_password',
  //   params: JSON.stringify(params),
  //   authenticated: false,
  //   callback,
  // };
  // return request(requestParams);
}

export function resetPassword(params, callback) {
  callback(null, {});
  // const { resetToken, ...rest } = params;
  // return request(
  //   'reset_password',
  //   JSON.stringify({
  //     reset_token: resetToken, ...rest,
  //   }),
  //   callback,
  // );
}
