import { authenticatedRequest } from './apiService'

export function getAllAccessKey ({ perPage, page, search, sort }) {
  return authenticatedRequest({
    path: '/access_key.all',
    data: {
      per_page: perPage,
      page,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search
    }
  })
}

export function createAccessKey () {
  return authenticatedRequest({
    path: '/access_key.create',
    data: {}
  })
}

export function deleteAccessKeyById (id) {
  return authenticatedRequest({
    path: '/api_key.delete',
    data: { id }
  })
}
