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

export function uploadAvatar ({ avatar }) {
  const formData = new window.FormData()
  formData.append('avatar', avatar)
  return authenticatedMultipartRequest({
    path: '/me.upload_avatar',
    data: formData
  })
}

export function inviteAdmin ({ email, redirectUrl, globalRole }) {
  return authenticatedRequest({
    path: '/admin.create',
    data: {
      email,
      redirect_url: redirectUrl,
      global_role: globalRole
    }
  })
}

export function updateAdmin ({
  id,
  fullName,
  callingName,
  enabled,
  globalRole
}) {
  return authenticatedRequest({
    path: '/admin.update',
    data: {
      id,
      full_name: fullName,
      calling_name: callingName,
      enabled,
      global_role: globalRole
    }
  })
}

export function createAdmin ({
  resetToken,
  password,
  passwordConfirmation,
  email
}) {
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

export function login2Fa (passcode) {
  const payload =
    passcode.length === 6 ? { passcode } : { backup_code: passcode }
  return authenticatedRequest({
    path: '/admin.login_2fa',
    data: payload
  })
}

export function enable2Fa (passcode) {
  return authenticatedRequest({
    path: '/me.enable_2fa',
    data: {
      passcode
    }
  })
}

export function disable2Fa (passcode) {
  return authenticatedRequest({
    path: '/me.disable_2fa',
    data: {
      passcode
    }
  })
}

export function createBackupCodes () {
  return authenticatedRequest({
    path: '/me.create_backup_codes'
  })
}
export function createSecretCode () {
  return authenticatedRequest({
    path: '/me.create_secret_code'
  })
}
