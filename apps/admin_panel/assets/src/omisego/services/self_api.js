import request from './api_service';

export function getCurrentUser(callback) {
  const requestParams = {
    path: 'me.get',
    params: null,
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function getCurrentAccount(callback) {
  const requestParams = {
    path: 'me.get_account',
    params: null,
    authenticated: true,
    callback,
  };
  return request(requestParams);
}
