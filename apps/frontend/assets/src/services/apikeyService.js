import { authenticatedRequest } from './apiService'

export function getAllApikey ({ perPage, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/api_key.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function createApikey ({ owner }) {
  return authenticatedRequest({
    path: '/api_key.create',
    data: {
      owner_app: owner
    }
  })
}

export function deleteApiKeyById (id) {
  return authenticatedRequest({
    path: '/api_key.delete',
    data: { id }
  })
}
export function updateApiKey ({ id, expired }) {
  return authenticatedRequest({
    path: '/api_key.update',
    data: { id, expired }
  })
}
