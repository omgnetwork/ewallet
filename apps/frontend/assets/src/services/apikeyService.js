import { authenticatedRequest } from './apiService'

export function getAllApikey ({ perPage, sort, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/api_key.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function createApikey ({ name }) {
  return authenticatedRequest({
    path: '/api_key.create',
    data: {
      name
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
