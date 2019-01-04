import { authenticatedRequest } from './apiService'

export function getActivityLogs ({ perPage, sortBy, sortDir, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/activity.all',
    data: {
      per_page: perPage,
      sort_by: sortBy,
      sort_dir: sortDir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}
