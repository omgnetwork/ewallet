import * as currentUserService from '../services/currentUserService'
import * as adminService from '../services/adminService'
import { createActionCreator } from '../utils/createActionCreator'
export const getCurrentUser = () =>
  createActionCreator({
    actionName: 'CURRENT_USER',
    action: 'REQUEST',
    service: currentUserService.getCurrentUser
  })

export const updateCurrentUserAvatar = ({ avatar }) =>
  createActionCreator({
    actionName: 'CURRENT_USER',
    action: 'UPDATE',
    service: () => adminService.uploadAvatar({ avatar })
  })

export const updateCurrentUserEmail = ({ email, redirectUrl }) =>
  createActionCreator({
    actionName: 'CURRENT_USER_EMAIL',
    action: 'UPDATE',
    service: () => currentUserService.updateCurrentUserEmail({ email, redirectUrl })
  })
