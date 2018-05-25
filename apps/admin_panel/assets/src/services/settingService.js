import { authenticatedRequest } from './apiService'

export function updateAccountInfo ({ id, name, description }) {
  return authenticatedRequest({
    path: '/account.update',
    data: {
      id,
      name,
      description
    }
  })
}

export function assignMember ({ userId, accountId, roleName, url }) {
  return authenticatedRequest({
    path: '/account.assign_user',
    data: {
      redirect_url: url,
      user_id: userId,
      account_id: accountId,
      role_name: roleName
    }
  })
}

export function inviteMember ({ email, accountId, roleName, url }) {
  return authenticatedRequest({
    path: '/account.assign_user',
    data: {
      email,
      redirect_url: url,
      account_id: accountId,
      role_name: roleName
    }
  })
}

export function unassignMember ({ userId, accountId }) {
  return authenticatedRequest({
    path: '/account.unassign_user',
    data: {
      user_id: userId,
      account_id: accountId
    }
  })
}

export function listMembers ({ accountId }) {
  return authenticatedRequest({
    path: '/account.list_users',
    data: {
      account_id: accountId
    }
  })
}

