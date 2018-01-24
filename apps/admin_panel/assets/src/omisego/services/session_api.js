import request from './api_service';

export function login(params, callback) {
  return request('login', JSON.stringify(params), callback);
}

export function logout(callback) {
  return request('logout', null, callback);
}

export function forgotPassword(params, callback) {
  callback(null, {});
  // return request('forgot_password', JSON.stringify(params), callback);
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
