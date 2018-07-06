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

export function assignMember ({ userId, accountId, role, redirectUrl }) {
  return authenticatedRequest({
    path: '/account.assign_user',
    data: {
      redirect_url: redirectUrl,
      user_id: userId,
      account_id: accountId,
      role_name: role
    }
  })
}

export function inviteMember ({ email, accountId, role, redirectUrl }) {
  return authenticatedRequest({
    path: '/account.assign_user',
    data: {
      email,
      redirect_url: redirectUrl,
      account_id: accountId,
      role_name: role
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
    path: '/account.get_members',
    data: {
      id: accountId
    }
  })
}
