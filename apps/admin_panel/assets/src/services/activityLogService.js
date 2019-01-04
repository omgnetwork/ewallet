import { authenticatedRequest } from './apiService'

export function getActivityLogs ({ perPage, page, sortBy, sortDir, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/activity_log.all',
    data: {
      page,
      per_page: perPage,
      sort_by: sortBy,
      sort_dir: sortDir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}
