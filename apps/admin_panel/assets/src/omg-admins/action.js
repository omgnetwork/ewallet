import * as adminService from '../services/adminService'
import { createPaginationActionCreator } from '../utils/createActionCreator'

export const getAllAdmins = ({ page, perPage, cacheKey, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'ADMINS',
    action: 'REQUEST',
    service: () =>
      adminService.getAllAdmins({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })
