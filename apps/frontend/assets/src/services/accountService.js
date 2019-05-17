import { authenticatedRequest, authenticatedMultipartRequest } from './apiService'
export function getAllAccounts ({ perPage, page, sort, query, search, searchTerms, matchAny }) {
  return authenticatedRequest({
    path: '/account.all',
    data: {
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms,
      match_any: matchAny
    }
  })
}

export function createAccount ({ name, description, category }) {
  return authenticatedRequest({
    path: '/account.create',
    data: { name, description, category_ids: category ? [category] : [] }
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

export function updateAccountInfo ({ id, name, description, categoryIds }) {
  return authenticatedRequest({
    path: '/account.update',
    data: {
      id,
      name,
      description,
      category_ids: categoryIds
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

export function assignKey ({ keyId, accountId, role }) {
  return authenticatedRequest({
    path: '/account.assign_key',
    data: {
      account_id: accountId,
      key_id: keyId,
      role_name: role
    }
  })
}

export function unassignKey ({ keyId, accountId }) {
  return authenticatedRequest({
    path: '/account.unassign_key',
    data: {
      account_id: accountId,
      key_id: keyId
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

export function listMembers ({ accountId, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/account.get_admin_user_memberships',
    data: {
      id: accountId,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getConsumptionsByAccountId ({
  accountId,
  perPage,
  page,
  sort,
  search,
  searchTerms,
  matchAll,
  matchAny
}) {
  return authenticatedRequest({
    path: '/account.get_transaction_consumptions',
    data: {
      id: accountId,
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getUsersByAccountId ({ accountId, perPage, page, sort, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/account.get_users',
    data: {
      id: accountId,
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getKeysByAccountId ({ accountId, perPage, page, sort, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/account.get_key_memberships',
    data: {
      id: accountId,
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}
