import urlJoin from 'url-join'
export function buildApiURL (apiPath, baseUrl = BACKEND_URL) {
  return urlJoin(baseUrl, apiPath)
}

function serialize (obj, parentKey) {
  let queryStr = []
  for (var key in obj) {
    if (!obj.hasOwnProperty(key)) {
      continue
    }
    let paramKey = parentKey ? `${parentKey}[${key}]` : key
    let paramVal = obj[key]
    if (typeof paramVal === 'object') {
      queryStr.push(serialize(paramVal, paramKey))
    } else {
      queryStr.push(encodeURIComponent(paramKey) + '=' + encodeURIComponent(paramVal))
    }
  }
  return queryStr.join('&')
}

export function appendParams (url, params) {
  if (Object.keys(params).length === 0) {
    return url
  }
  let prefix = url.match(/\?/) ? '&' : '?'
  return `${url}${prefix}${serialize(params)}`
}
