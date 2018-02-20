import request from './api_service';

export function getAll(params) {
  const {
    per, sort, query, ...rest
  } = params;
  const requestParams = {
    path: 'user.all',
    params: JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function create(params) {
  const requestParams = {
    path: 'user.create',
    params: JSON.stringify(params),
    authenticated: true,
  };
  return request(requestParams);
}

export function getUser(params) {
  const { id } = params;
  const requestParams = {
    path: 'user.get',
    params: JSON.stringify({
      id,
    }),
    authenticated: true,
  };
  return request(requestParams);
}
