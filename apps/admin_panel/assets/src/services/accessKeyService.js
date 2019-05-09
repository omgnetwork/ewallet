import { authenticatedRequest } from './apiService'

export function getAccessKeys ({ perPage, page, matchAll, matchAny, sort }) {
  return authenticatedRequest({
    path: '/access_key.all',
    data: {
      per_page: perPage,
      page,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getAccessKey (id) {
  return authenticatedRequest({
    path: '/access_key.get',
    data: { id }
  })
}

export function createAccessKey ({ name, globalRole, accountId, roleName }) {
  return authenticatedRequest({
    path: '/access_key.create',
    data: {
      name,
      global_role: globalRole,
      account_id: accountId,
      role_name: roleName
    }
  })
}
export function updateAccessKey ({ id, expired }) {
  return authenticatedRequest({
    path: '/access_key.update',
    data: { id, expired }
  })
}

export function deleteAccessKeyById (id) {
  return authenticatedRequest({
    path: '/api_key.delete',
    data: { id }
  })
}

export function getAccessKeyMemberships ({
  id,
  startAfter,
  startBy,
  perPage,
  matchAll,
  matchAny,
  sortBy,
  sortDir
}) {
  return authenticatedRequest({
    path: '/access_key.get_account_memberships',
    data: {
      id,
      start_after: startAfter,
      start_by: startBy,
      per_page: perPage,
      match_all: matchAll,
      match_any: matchAny,
      sort_by: sortBy,
      sort_dir: sortDir
    }
  })
}
