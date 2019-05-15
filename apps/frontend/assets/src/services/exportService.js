import { authenticatedRequest } from './apiService'
export function getExportFileById (id) {
  return authenticatedRequest({
    path: '/export.get',
    data: {
      id
    }
  })
}

export function getExportFiles ({ page, perPage, matchAll, matchAny, sortBy, sortDir }) {
  return authenticatedRequest({
    path: '/export.all',
    data: {
      page,
      per_page: perPage,
      match_all: matchAll,
      match_any: matchAny,
      sort_by: sortBy,
      sort_dir: sortDir
    }
  })
}

export function downloadExportFileById (id) {
  return authenticatedRequest({
    path: '/export.download',
    data: {
      id
    }
  })
}
