import { authenticatedRequest } from './apiService'

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

export function updateCurrentUserEmail ({ email, redirectUrl }) {
  return authenticatedRequest({
    path: 'me.update_email',
    data: {
      email,
      redirect_url: redirectUrl
    }
  })
}
