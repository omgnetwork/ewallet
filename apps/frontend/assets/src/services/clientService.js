import { unAuthenticatedClientRequest } from './apiService'
export function updateUserPassword ({ email, token, password, passwordConfirmation }) {
  return unAuthenticatedClientRequest({
    path: 'user.update_password',
    data: {
      email,
      token,
      password,
      password_confirmation: passwordConfirmation
    }
  })
}
