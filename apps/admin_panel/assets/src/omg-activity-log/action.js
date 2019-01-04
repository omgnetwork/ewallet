import { createPaginationActionCreator } from '../utils/createActionCreator'
import * as activityLogService from '../services/activityLogService'
export const getActivityLogs = ({ matchAll, matchAny, page, perPage, cacheKey }) =>
  createPaginationActionCreator({
    action: 'REQUEST',
    actionName: 'ACTIVITIES',
    service: () =>
      activityLogService.getActivityLogs({
        perPage,
        page,
        sortDir: 'desc',
        sortBy: 'created_at',
        matchAll,
        matchAny
      }),
    cacheKey
  })
