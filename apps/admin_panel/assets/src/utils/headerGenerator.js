import CONSTANT from '../constants'
import localStorage from '../utils/localStorage'
import btoa from 'btoa'
export function createAuthenticationHeader ({ auth, accessToken }) {
  const createAuthorizationHeader = key => ({ Authorization: `OMGAdmin ${btoa(key)}` })
  return auth
    ? createAuthorizationHeader(`${accessToken.user_id}:${accessToken.authentication_token}`)
    : {}
}

function createAccountIdHeader (currentAccountId) {
  return currentAccountId ? { 'OMGAdmin-Account-ID': currentAccountId } : {}
}

export default function createHeaders ({
  auth,
  headerOption,
  accessToken = localStorage.get(CONSTANT.AUTHENTICATION_TOKEN),
  currentAccountId = localStorage.get(CONSTANT.CURRENT_ACCOUNT_ID_KEY)
}) {
  return {
    Accept: 'application/vnd.omisego.v1+json',
    ...createAuthenticationHeader({ auth, accessToken }),
    ...createAccountIdHeader(currentAccountId),
    ...headerOption
  }
}
