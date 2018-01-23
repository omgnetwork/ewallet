import request from './api_service';

export function getAll(params, callback) {
  const {
    per, sort, query, ...rest
  } = params;
  return request(
    'transaction.all',
    JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    callback,
  );
}

export function create(params, callback) {
  callback(null, { id: 1234 });
  // return request('transactions.create', JSON.stringify(params), callback);
}

export function get(id, callback) {
  return request('transaction.get', JSON.stringify({ id }), callback);
}
