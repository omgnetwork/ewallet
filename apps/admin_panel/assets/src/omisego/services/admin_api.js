import request from './api_service';

export default function getAll(params, callback) {
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
