import btoa from 'btoa'
import CONSTANT from '../constants'
import localStorage from '../utils/localStorage'
export function createAuthenticationHeader ({ auth, accessToken }) {
  const createAuthorizationHeader = key => ({
    Authorization: `OMGAdmin ${btoa(key)}`
  })
  const {
    user_id,
    pre_authentication_token,
    authentication_token
  } = accessToken
  return auth
    ? createAuthorizationHeader(
      `${user_id}:${pre_authentication_token || authentication_token}`
    )
    : {}
}

export default function createHeaders ({
  auth,
  headerOption,
  accessToken = localStorage.get(CONSTANT.AUTHENTICATION_TOKEN) || {}
}) {
  return {
    Accept: 'application/vnd.omisego.v1+json',
    ...createAuthenticationHeader({ auth, accessToken }),
    ...headerOption
  }
}
