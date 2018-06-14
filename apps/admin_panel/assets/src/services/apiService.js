import axios from 'axios'
import { buildApiURL } from '../utils/urlBuilder'
import createHeader from '../utils/headerGenerator'

export function request ({ path, data, headers }) {
  const url = buildApiURL(path)
  return axios.post(url, data, { headers })
}
export function authenticatedRequest ({ path, data, idempotencyToken }) {
  let headers = createHeader({ auth: true })
  if (idempotencyToken) {
    headers = { ...headers, ...{ 'Idempotency-Token': idempotencyToken } }
  }
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
