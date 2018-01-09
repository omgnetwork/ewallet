import request from './api_service';

export function getAll(params, callback) {
  const { per, ...rest } = params;
  return request('account.all', JSON.stringify({ per_page: per, ...rest }), callback);
}

export function create(params, callback) {
  return request('account.create', JSON.stringify(params), callback);
}
