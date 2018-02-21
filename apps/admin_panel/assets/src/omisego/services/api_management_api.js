import request from './api_service';

export function getAll(params, callback) {
  const {
    per, sort, query, ...rest
  } = params;
  const requestParams = {
    path: 'api_key.all',
    params: JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function create(params, callback) {
  const requestParams = {
    path: 'api_key.create',
    params: JSON.stringify({
      owner_app: params.owner,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}

export function deleteKey(params, callback) {
  const { id } = params;
  const requestParams = {
    path: 'api_key.delete',
    params: JSON.stringify({
      id,
    }),
    authenticated: true,
    callback,
  };
  return request(requestParams);
}
