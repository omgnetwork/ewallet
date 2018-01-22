import request from './api_service';

export function getCurrentUser(callback) {
  return request('me.get', null, callback);
}

export function getCurrentAccount(callback) {
  const mock = {
    object: 'account',
    created_at: '2018-01-12T09:25:09.192138Z',
    description: 'Account 3 (Non-Master)',
    id: '6490948c-f478-4236-ba15-64f48adbbb60',
    master: false,
    name: 'account03',
    updated_at: '2018-01-12T09:25:09.192147Z',
  };
  callback(null, mock);
  // return request('me.get_account', null, callback);
}
