import { unAuthenticatedRequest } from './apiService'
export function updateUserPassword () {
  return unAuthenticatedRequest({
    path: 'user.update_password',
    data: {}
  })
}
