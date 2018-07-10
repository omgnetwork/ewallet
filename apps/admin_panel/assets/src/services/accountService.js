import { authenticatedRequest, authenticatedMultipartRequest } from './apiService'
export function getAllAccounts ({ perPage, page, sort, query, search, searchTerms }) {
  return authenticatedRequest({
    path: '/account.all',
    data: {
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms
    }
  })
}

export function createAccount ({ name, description, category }) {
  return authenticatedRequest({
    path: '/account.create',
    data: { name, description, category_ids: [category] }
  })
}

export function getAccountById (id) {
  return authenticatedRequest({
    path: '/account.get',
    data: { id }
  })
}

export function uploadAccountAvatar ({ accountId, avatar }) {
  const formData = new window.FormData()
  formData.append('id', accountId)
  formData.append('avatar', avatar)
  return authenticatedMultipartRequest({
    path: '/account.upload_avatar',
    data: formData
  })
}

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
