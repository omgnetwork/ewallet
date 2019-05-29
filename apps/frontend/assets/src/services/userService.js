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

export function updateUser ({ id, username, providerUserId, fullName, callingName }) {
  return authenticatedRequest({
    path: '/user.update',
    data: {
      id,
      username,
      provider_user_id: providerUserId,
      full_name: fullName,
      calling_name: callingName
    }
  })
}

export function getUserById (id) {
  return authenticatedRequest({
    path: '/user.get',
    data: { id }
  })
}
