import axios from 'axios'
import createHeader from '../utils/headerGenerator'
import { API_URL } from '../config'
import urlJoin from 'url-join'
export function request ({ path, data, headers }) {
  return axios.post(urlJoin(API_URL, path), data, { headers })
}
export function authenticatedRequest ({ path, data }) {
  const headers = createHeader({ auth: true })
  return request({ path, data, headers })
}
export function unAuthenticatedRequest ({ path, data }) {
  const headers = createHeader({ auth: false })
  return request({ path, data, headers })
}
export function authenticatedMultipartRequest ({ path, data }) {
  const headers = createHeader({
    auth: true,
    headerOption: { 'content-type': 'multipart/form-data' }
  })
  return request({ path, data, headers })
}
