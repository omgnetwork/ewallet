import * as sessionService from '../services/sessionService'
import { createActionCreator } from '../utils/createActionCreator'
export const login = ({ email, password, rememberMe }) => createActionCreator({actionName: 'SESSION',
  action: 'LOGIN',
  service: async () => {
    const sessionResult = await sessionService.login({ email, password })
    const account = sessionService.getCurrentAccountFromLocalStorage()
    if (sessionResult.data.success) {
      sessionService.setAccessToken(sessionResult.data.data)
      if (!account) sessionService.setCurrentAccount(sessionResult.data.data.account)
    }
    return sessionResult
  }
})

export const logout = () =>
  createActionCreator({
    actionName: 'SESSION',
    action: 'LOGOUT',
    service: () => sessionService.logout()
  })

export const sendResetPasswordEmail = ({ email, redirectUrl }) =>
  createActionCreator({
    actionName: 'PASSWORD',
    action: 'RESET',
    service: () =>
      sessionService.resetPassword({
        email,
        redirectUrl: `${redirectUrl}?token={token}&email={email}`
      })
  })

export const updatePasswordWithResetToken = ({
  resetToken,
  password,
  passwordConfirmation,
  email
}) =>
  createActionCreator({
    actionName: 'PASSWORD_TOKEN',
    action: 'UPDATE',
    service: () =>
      sessionService.updatePasswordWithResetToken({
        resetToken,
        password,
        passwordConfirmation,
        email
      })
  })

export const updatePassword = ({ password, passwordConfirmation, oldPassword }) =>
  createActionCreator({
    actionName: 'PASSWORD',
    action: 'UPDATE',
    service: () =>
      sessionService.updatePassword({
        oldPassword,
        password,
        passwordConfirmation
      })
  })
