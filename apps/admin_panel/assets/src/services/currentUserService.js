import { authenticatedRequest } from './apiService'
import { ADMIN_API_URL } from '../config'

export function getCurrentUser () {
  return authenticatedRequest({
    path: 'me.get',
    data: {}
  })
}

export function getCurrentUserAccount () {
  return authenticatedRequest({
    path: 'me.get_account',
    data: {}
  })
}

export function updateCurrentUserEmail ({ email }) {
  return authenticatedRequest({
    path: 'me.update_email',
    data: {
      email,
      redirect_url: `${ADMIN_API_URL}?email={email}`
    }
  })
}
