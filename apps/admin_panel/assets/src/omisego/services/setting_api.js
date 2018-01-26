import request from './api_service';

export function updateAccountInfo(params, callback) {
  return request('account.update', JSON.stringify(params), callback);
}

export function assignMember(params, callback) {
  const { userId, accountId, roleName } = params;
  return request('account.assign_user', JSON.stringify({
    user_id: userId,
    account_id: accountId,
    role_name: roleName,
  }), callback);
}

export function unassignMember(params, callback) {
  const { userId, accountId } = params;
  return request('account.unassign_user', JSON.stringify({
    user_id: userId,
    account_id: accountId,
  }), callback);
}

export function listMembers(params, callback) {
  const { accountId } = params;
  return request('account.list_users', JSON.stringify({
    account_id: accountId,
  }), callback);
}

export function updateMember(params, callback) {
  // return request('member.update', JSON.stringify(params), callback);
  const mock = params;
  callback(null, {
    data: mock,
  });
}
