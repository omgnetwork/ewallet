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

export function getApiKey (id) {
  return authenticatedRequest({
    path: '/api_key.get',
    data: { id }
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

export function updateApiKey ({ id, name }) {
  return authenticatedRequest({
    path: '/api_key.update',
    data: { id, name }
  })
}

export function enableApiKey ({ id, enabled }) {
  return authenticatedRequest({
    path: '/api_key.enable_or_disable',
    data: { id, enabled }
  })
}
