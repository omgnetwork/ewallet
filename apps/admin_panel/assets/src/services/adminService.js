import {
  authenticatedRequest,
  authenticatedMultipartRequest,
  unAuthenticatedRequest
} from './apiService'

export function getAllAdmins ({ perPage, sort, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/admin.all',
    data: {
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}

export function getAdminById (id) {
  return authenticatedRequest({
    path: '/admin.get',
    data: { id }
  })
}

export function uploadAvatar ({ id, avatar }) {
  const formData = new window.FormData()
  formData.append('id', id)
  formData.append('avatar', avatar)
  return authenticatedMultipartRequest({
    path: '/me.upload_avatar',
    data: formData
  })
}

export function createAdmin ({ resetToken, password, passwordConfirmation, email }) {
  return unAuthenticatedRequest({
    path: '/invite.accept',
    data: {
      email,
      token: resetToken,
      password,
      password_confirmation: passwordConfirmation
    }
  })
}
