import request from './api_service';

export function updateAccountInfo(params) {
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
  };
  return request(requestParams);
}

export function assignMember(params) {
  const {
    userId,
    accountId,
    roleName,
    url,
  } = params;
  const requestParams = {
    path: 'account.assign_user',
    params: JSON.stringify({
      redirect_url: url,
      user_id: userId,
      account_id: accountId,
      role_name: roleName,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function inviteMember(params) {
  const {
    email,
    accountId,
    roleName,
    url,
  } = params;

  const requestParams = {
    path: 'account.assign_user',
    params: JSON.stringify({
      email,
      redirect_url: url,
      account_id: accountId,
      role_name: roleName,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function unassignMember(params) {
  const { userId, accountId } = params;
  const requestParams = {
    path: 'account.unassign_user',
    params: JSON.stringify({
      user_id: userId,
      account_id: accountId,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function listMembers(params) {
  const { accountId } = params;
  const requestParams = {
    path: 'account.list_users',
    params: JSON.stringify({
      account_id: accountId,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function uploadAvatar(params) {
  const {
    accountId, avatar,
  } = params;

  const formData = new FormData();
  formData.append('id', accountId);
  formData.append('avatar', avatar);

  const requestParams = {
    path: 'account.upload_avatar',
    params: formData,
    authenticated: true,
    isMultipart: true,
  };

  return request(requestParams);
}
