import request from './api_service';

export function getAll(params) {
  const {
    per, sort, query, ...rest
  } = params;
  const requestParams = {
    path: 'admin.all',
    params: JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function uploadAvatar(params) {
  const {
    id, avatar,
  } = params;

  const formData = new FormData();
  formData.append('id', id);
  formData.append('avatar', avatar);

  const requestParams = {
    path: 'admin.upload_avatar',
    params: formData,
    authenticated: true,
    isMultipart: true,
  };

  return request(requestParams);
}

export function createAdmin(params) {
  const {
    resetToken, password, passwordConfirmation, email,
  } = params;
  const requestParams = {
    path: 'invite.accept',
    params: JSON.stringify({
      email, token: resetToken, password, password_confirmation: passwordConfirmation,
    }),
    authenticated: false,
  };
  return request(requestParams);
}
