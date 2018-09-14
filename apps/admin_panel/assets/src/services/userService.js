import { authenticatedRequest } from './apiService'

export function getUsers ({ accountId, perPage, sort, page, search, searchTerms }) {
  return authenticatedRequest({
    path: '/account.get_users',
    data: {
      id: accountId,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms,
      page
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
