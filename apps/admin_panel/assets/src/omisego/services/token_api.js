import request from './api_service';

export function getAll(params) {
  const {
    per, sort, query, ...rest
  } = params;
  const requestParams = {
    path: 'minted_token.all',
    params: JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    authenticated: true,
  };
  return request(requestParams);
}

export function create(params, callback) {
  callback(null, { id: 1234 });
}
