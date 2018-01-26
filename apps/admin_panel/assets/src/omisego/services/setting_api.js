import request from './api_service';

export function updateAccountInfo(params, callback) {
  const {
    id, name, description, master,
  } = params;
  const requestParams = {
    path: 'account.update',
    params: JSON.stringify({
      id,
      name,
      description,
      master,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function assignMember(params, callback) {
  const { userId, accountId, roleName } = params;
  const requestParams = {
    path: 'account.assign_user',
    params: JSON.stringify({
      user_id: userId,
      account_id: accountId,
      role_name: roleName,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function unassignMember(params, callback) {
  const { userId, accountId } = params;
  const requestParams = {
    path: 'account.unassign_user',
    params: JSON.stringify({
      user_id: userId,
      account_id: accountId,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function listMembers(params, callback) {
  const { accountId } = params;
  const requestParams = {
    path: 'account.list_users',
    params: JSON.stringify({
      account_id: accountId,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function updateMember(params, callback) {
  // return request('member.update', JSON.stringify(params), callback);
  const mock = params;
  callback(null, {
    data: mock,
  });
}
