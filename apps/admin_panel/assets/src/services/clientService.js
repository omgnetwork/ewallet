import { unAuthenticatedRequest } from './apiService'
export function updateUserPassword ({ email, token, password, passwordConfirmation }) {
  return unAuthenticatedRequest({
    path: 'user.update_password',
    data: {
      email,
      token,
      password,
      password_confirmation: passwordConfirmation
    }
  })
}
