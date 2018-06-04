import { ADMIN_API_BASE_URL } from '../../config'
import urlJoin from 'url-join'
export function buildApiURL (apiPath, baseUrl = ADMIN_API_BASE_URL) {
  return urlJoin(baseUrl, apiPath)
}
