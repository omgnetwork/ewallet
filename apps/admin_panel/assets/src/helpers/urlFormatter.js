import queryString from 'query-string';

export const urlFormatter = {
  formatURL,
  processURL,
};

function formatURL(path, query = {}) {
  if (!query || query === {}) { return path; }
  const filteredQuery = {};
  Object.keys(query).forEach((key) => {
    if (query[key] !== '') { filteredQuery[key] = query[key]; }
  });
  const queryStr = queryString.stringify(filteredQuery);
  return `${path}?${queryStr}`;
}

function processURL(location) {
  return queryString.parse(location.search);
}
