import * as adminService from '../services/adminService'
import { createPaginationActionCreator, createActionCreator } from '../utils/createActionCreator'

export const getAdmins = ({ page, perPage, cacheKey, matchAll, matchAny }) =>
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

export const getAdminById = id =>
  createActionCreator({
    actionName: 'ADMIN',
    action: 'REQUEST',
    service: () => adminService.getAdminById(id)
  })
