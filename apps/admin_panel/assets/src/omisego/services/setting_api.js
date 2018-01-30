import request from './api_service';
import { OMISEGO_BASE_URL } from '../config';

// When we need to customize the invitation params (add, rename, remove), we can config it here.
export const invitationConst = {
  params: {
    email: 'email',
    token: 'token',
  },
  pathname: 'invitation_accept',
};

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

export function inviteMember(params, callback) {
  const { email, accountId, roleName } = params;

  /* This will generate something like `email={email}&token={token}&` */
  let inviteParams = Object.keys(invitationConst.params)
    .reduce((previousValue, currentValue) => `${previousValue}${currentValue}={${currentValue}}&`, '');

  // Remove last '&'
  inviteParams = inviteParams.substr(0, inviteParams.length - 1);

  const requestParams = {
    path: 'account.assign_user',
    params: JSON.stringify({
      email,
      base_url: `${OMISEGO_BASE_URL}${invitationConst.pathname}?${inviteParams}`,
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
