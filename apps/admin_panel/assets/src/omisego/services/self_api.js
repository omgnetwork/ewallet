import request from './api_service';

export function getCurrentUser() {
  const requestParams = {
    path: 'me.get',
    params: null,
    authenticated: true,
  };
  return request(requestParams);
}

export function getCurrentAccount() {
  const requestParams = {
    path: 'me.get_account',
    params: null,
    authenticated: true,
  };
  return request(requestParams);
}
