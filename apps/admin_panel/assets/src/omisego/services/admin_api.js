import request from './api_service';

export function getAll(params, callback) {
  const {
    per, sort, query, ...rest
  } = params;
  const requestParams = {
    path: 'admin.all',
    params: JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function uploadAvatar(params, callback) {
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
    callback,
    isMultipart: true,
  };

  return request(requestParams);
}
