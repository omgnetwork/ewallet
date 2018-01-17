import request from './api_service';

export default function getAll(params, callback) {
  const {
    per, sort, query, ...rest
  } = params;
  return request(
    'admin.all',
    JSON.stringify({
      per_page: per, sort_by: sort.by, sort_dir: sort.dir, search_term: query, ...rest,
    }),
    callback,
  );
}
