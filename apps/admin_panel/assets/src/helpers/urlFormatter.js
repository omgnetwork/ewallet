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

export function formatEmailLink(struct) {
  /* This will generate something like `email={email}&token={token}&` */
  let params = Object.keys(struct.params)
    .reduce((previousValue, currentValue) => `${previousValue}${currentValue}={${currentValue}}&`, '');
  // Remove last '&'
  params = params.substr(0, params.length - 1);
  return `${window.location.origin}/${struct.pathname}?${params}`;
}
