import urlJoin from 'url-join'
export function buildApiURL (apiPath, baseUrl = BACKEND_URL) {
  return urlJoin(baseUrl, apiPath)
}
