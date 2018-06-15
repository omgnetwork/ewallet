import { authenticatedRequest, unAuthenticatedRequest } from './apiService'
import localStorage from '../utils/localStorage'
import CONSTANT from '../constants'

export function getCurrentAccountFromLocalStorage () {
  return localStorage.get(CONSTANT.CURRENT_ACCOUNT_ID)
}

export function getAccessToken () {
  return localStorage.get(CONSTANT.AUTHENTICATION_TOKEN)
}
export function setCurrentAccount (data) {
  return localStorage.set(CONSTANT.CURRENT_ACCOUNT_ID, data)
}

export function setAccessToken (data) {
  return localStorage.set(CONSTANT.AUTHENTICATION_TOKEN, data)
}

export function login ({ email, password }) {
  return unAuthenticatedRequest({
    path: '/login',
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

export function updatePassword ({ resetToken, password, passwordConfirmation, email }) {
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
