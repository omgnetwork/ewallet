import queryString from 'query-string';

export function formatURL(path, query = {}) {
  if (!query || query === {}) { return path; }
  const filteredQuery = {};
  Object.keys(query).forEach((key) => {
    if (query[key] !== '') { filteredQuery[key] = query[key]; }
  });
  const queryStr = queryString.stringify(filteredQuery);
  return `${path}?${queryStr}`;
}

export function processURL(location) {
  return queryString.parse(location.search);
}

export function accountURL(session, path) {
  return `/a/${session.currentAccount.id}${path}`;
}
