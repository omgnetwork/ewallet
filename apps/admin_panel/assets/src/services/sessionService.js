import { authenticatedRequest, unAuthenticatedRequest } from './apiService'
import localStorage from '../utils/localStorage'
import CONSTANT from '../constants'

export function getRecentAccountFromLocalStorage () {
  return localStorage.get(CONSTANT.RECENT_ACCOUNT)
}

export function getAccessToken () {
  return localStorage.get(CONSTANT.AUTHENTICATION_TOKEN)
}
export function setRecentAccount (data) {
  return localStorage.set(CONSTANT.RECENT_ACCOUNT, data)
}

export function setAccessToken (data) {
  return localStorage.set(CONSTANT.AUTHENTICATION_TOKEN, data)
}

export function removeAccessDataFromLocalStorage () {
  localStorage.set(CONSTANT.AUTHENTICATION_TOKEN, null)
  localStorage.set(CONSTANT.RECENT_ACCOUNT, null)
}

export function login ({ email, password }) {
  return unAuthenticatedRequest({
    path: '/admin.login',
    data: { email, password }
  })
}

export function logout () {
  return authenticatedRequest({
    path: '/me.logout',
    data: {}
  })
}

export function resetPassword ({ email, redirectUrl }) {
  return unAuthenticatedRequest({
    path: '/admin.reset_password',
    data: { email, redirect_url: redirectUrl }
  })
}

export function updatePasswordWithResetToken ({
  resetToken,
  password,
  passwordConfirmation,
  email
}) {
  return unAuthenticatedRequest({
    path: '/admin.update_password',
    data: {
      email,
      token: resetToken,
      password,
      password_confirmation: passwordConfirmation
    }
  })
}

export function updatePassword ({ oldPassword, password, passwordConfirmation }) {
  return authenticatedRequest({
    path: '/me.update_password',
    data: {
      old_password: oldPassword,
      password,
      password_confirmation: passwordConfirmation
    }
  })
}
