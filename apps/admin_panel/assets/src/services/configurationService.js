import { authenticatedRequest } from './apiService'

export function getConfiguration ({ perPage, sort, page, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/configuration.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function updateConfiguration (config) {
  return authenticatedRequest({
    path: '/configuration.update',
    data: config
  })
}
