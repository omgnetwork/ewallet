import { authenticatedRequest } from './apiService'

export function getUsers ({ accountId, perPage, sort, page, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/user.all',
    data: {
      id: accountId,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      page,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function createUser ({ username, providerUserId }) {
  return authenticatedRequest({
    path: '/user.create',
    data: {
      username,
      provider_user_id: providerUserId
    }
  })
}

export function getUserById (id) {
  return authenticatedRequest({
    path: '/user.get',
    data: { id }
  })
}
