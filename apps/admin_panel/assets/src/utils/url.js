
function serialize (obj, parentKey) {
  let queryStr = []
  for (let key in obj) {
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

export function isAbsoluteURL (url) {
	let schemeWhitelist =  ["http://", "https://", "ws://", "wss://"];
	for (let i = 0; i < schemeWhitelist.length; i++) {
		let scheme =  schemeWhitelist[i];
		if (url.startsWith(scheme)) {
			return true;
		}
	}
	return false;
};
