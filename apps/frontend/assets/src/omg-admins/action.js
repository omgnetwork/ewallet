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

export const inviteAdmin = ({ email, redirectUrl, globalRole }) =>
  createActionCreator({
    actionName: 'INVITE_ADMIN',
    action: 'REQUEST',
    service: () =>
      adminService.inviteAdmin({
        email,
        redirectUrl: `${redirectUrl}?token={token}&email={email}`,
        globalRole
      })
  })

export const updateAdmin = ({ id, fullName, callingName, enabled, globalRole }) =>
  createActionCreator({
    actionName: 'ADMIN',
    action: 'UPDATE',
    service: () => adminService.updateAdmin({ id, fullName, callingName, enabled, globalRole })
  })
