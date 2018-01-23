import request from './api_service';

export function getCurrentUser(callback) {
  return request('me.get', null, callback);
}

export function getCurrentAccount(callback) {
  return request('me.get_account', null, callback);
}
