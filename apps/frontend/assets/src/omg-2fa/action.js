import { createActionCreator } from '../utils/createActionCreator'
import * as adminService from '../services/adminService'
import * as sessionService from '../services/sessionService'
export const login2Fa = passcode =>
  createActionCreator({
    actionName: '2FA',
    action: 'LOGIN',
    service: async () => {
      const result = await adminService.login2Fa(passcode)
      if (result.data.success) {
        sessionService.setAccessToken(result.data.data)
      }
      return result
    }
  })

export const enable2Fa = passcode =>
  createActionCreator({
    actionName: '2FA',
    action: 'ENABLE',
    service: () => adminService.enable2Fa(passcode)
  })

export const disable2Fa = passcode =>
  createActionCreator({
    actionName: '2FA',
    action: 'DISABLE',
    service: () => adminService.disable2Fa(passcode)
  })

export const createBackupCodes = () =>
  createActionCreator({
    actionName: 'BACKUP_CODE',
    action: 'CREATE',
    service: () => adminService.createBackupCodes()
  })

export const createSecretCodes = () =>
  createActionCreator({
    actionName: 'SECRET_CODE',
    action: 'CREATE',
    service: () => adminService.createSecretCode()
  })
