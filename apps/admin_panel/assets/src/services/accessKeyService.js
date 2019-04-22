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
