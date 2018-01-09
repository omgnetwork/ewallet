import request from './api_service';

export function login(params, callback) {
  return request('login', JSON.stringify(params), callback);
}

export function logout(callback) {
  return request('logout', null, callback);
}
