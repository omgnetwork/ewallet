import CONSTANT from '../constants'
import localStorage from '../utils/localStorage'
import btoa from 'btoa'
export function createAuthenticationHeader ({ auth, accessToken }) {
  const createAuthorizationHeader = key => ({ Authorization: `OMGAdmin ${btoa(key)}` })
  return auth
    ? createAuthorizationHeader(`${accessToken.user_id}:${accessToken.authentication_token}`)
    : {}
}

export default function createHeaders ({
  auth,
  headerOption,
  accessToken = (localStorage.get(CONSTANT.AUTHENTICATION_TOKEN) || {}),
  currentAccountId
}) {
  return {
    Accept: 'application/vnd.omisego.v1+json',
    ...createAuthenticationHeader({ auth, accessToken }),
    ...headerOption
  }
}
