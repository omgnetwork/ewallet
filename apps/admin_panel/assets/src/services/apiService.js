import axios from 'axios'
import urlJoin from 'url-join'

import createHeader from '../utils/headerGenerator'
import { ADMIN_API_URL, CLIENT_API_URL } from '../config'

export const request = url => ({ path, data, headers }) => {
  const joinedPath = urlJoin(url, path)
  return axios.post(joinedPath, data, { headers })
}

export const adminRequest = request(ADMIN_API_URL)
export const clientRequest = request(CLIENT_API_URL)

export function unAuthenticatedClientRequest ({ path, data }) {
  const headers = createHeader({ auth: false })
  return clientRequest({ path, data, headers })
}

export function authenticatedRequest ({ path, data }) {
  const headers = createHeader({ auth: true })
  return adminRequest({ path, data, headers })
}
export function unAuthenticatedRequest ({ path, data }) {
  const headers = createHeader({ auth: false })
  return adminRequest({ path, data, headers })
}
export function authenticatedMultipartRequest ({ path, data }) {
  const headers = createHeader({
    auth: true,
    headerOption: { 'content-type': 'multipart/form-data' }
  })
  return adminRequest({ path, data, headers })
}
