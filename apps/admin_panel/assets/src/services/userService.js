import { authenticatedRequest } from './apiService'

export function getAllUsers ({ perPage, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/user.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function createUser (params) {
  return authenticatedRequest({
    path: '/user.create',
    data: params
  })
}

export function getUserById (id) {
  return authenticatedRequest({
    path: '/user.get',
    data: { id }
  })
}
