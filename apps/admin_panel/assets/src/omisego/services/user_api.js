import request from './api_service';

export function getAll(params, callback) {
  const {
    per, sort, query, ...rest
  } = params;
  return request(
    'user.all',
    JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    callback,
  );
}

export function create(params, callback) {
  return request('user.create', JSON.stringify(params), callback);
}
