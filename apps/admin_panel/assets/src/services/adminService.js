import { authenticatedRequest, authenticatedMultipartRequest } from './apiService'

export function getAllAdmins ({ per, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/admin.all',
    data: {
      per_page: per,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function uploadAvatar ({ id, avatar }) {
  const formData = new window.FormData()
  formData.append('id', id)
  formData.append('avatar', avatar)
  return authenticatedMultipartRequest({
    path: '/admin.upload_avatar',
    data: formData
  })
}

export function createAdmin ({ resetToken, password, passwordConfirmation, email }) {
  return authenticatedRequest({
    path: '/invite.accept',
    data: {
      email,
      token: resetToken,
      password,
      password_confirmation: passwordConfirmation
    }
  })
}
