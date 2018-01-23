import request from './api_service';

export function getAll(params, callback) {
  const {
    per, sort, query, ...rest
  } = params;
  return request(
    'account.all',
    JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    callback,
  );
}

export function create(params, callback) {
  return request('account.create', JSON.stringify(params), callback);
}

export function get(id, callback) {
  return request('account.get', JSON.stringify({ id }), callback);
}
