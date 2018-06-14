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

export function updateCurrentUser ({ email }) {
  return authenticatedRequest({
    path: 'me.update',
    data: { email }
  })
}
