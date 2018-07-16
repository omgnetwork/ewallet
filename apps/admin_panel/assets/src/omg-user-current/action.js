import * as currentUserSerivce from '../services/currentUserService'
import * as adminService from '../services/adminService'
import { createActionCreator } from '../utils/createActionCreator'
export const getCurrentUser = () =>
  createActionCreator({
    actionName: 'CURRENT_USER',
    action: 'REQUEST',
    service: currentUserSerivce.getCurrentUser
  })

export const updateCurrentUser = ({ avatar, email }) =>
  createActionCreator({
    actionName: 'CURRENT_USER',
    action: 'UPDATE',
    service: async () => {
      const resultUpdateCurrentUser = await currentUserSerivce.updateCurrentUser({ email })
      if (resultUpdateCurrentUser.data.success && avatar) {
        const userId = resultUpdateCurrentUser.data.data.id
        const resultUploadAvatar = await adminService.uploadAvatar({
          id: userId,
          avatar
        })
        return resultUploadAvatar
      }
      return resultUpdateCurrentUser
    }
  })
