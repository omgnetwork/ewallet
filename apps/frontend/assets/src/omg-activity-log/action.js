import { createPaginationActionCreator, createActionCreator } from '../utils/createActionCreator'
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

export const getActivityLogById = id =>
  createActionCreator({
    action: 'REQUEST',
    actionName: 'ACTIVITY',
    service: () => activityLogService.getActivityLogById(id)
  })
