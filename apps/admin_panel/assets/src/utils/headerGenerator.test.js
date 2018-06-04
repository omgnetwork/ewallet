import createHeaders from './headerGenerator'
import btoa from 'btoa'
describe('headerGenerator', () => {
  const currentAccountId = 'account_id'
  const accessToken = {userId: 'test1',authentication_token: 'test2'}
  test('function createHeaders should return correct header for [authenticated] request', () => {
    const header = createHeaders({
      auth: true,
      accessToken,
      currentAccountId
    })
    const AuthorizationEncoded = btoa(`${accessToken.user_id}:${accessToken.authentication_token}`)
    expect(header).toEqual({
      'Accept': 'application/vnd.omisego.v1+json',
      'Authorization': `OMGAdmin ${AuthorizationEncoded}`,
      'OMGAdmin-Account-ID': currentAccountId
    })
  })
  test('function createHeaders should return correct header for [unauthenticated] request', () => {
    const header = createHeaders({
      auth: false,
      accessToken,
      currentAccountId
    })
    expect(header).toEqual({
      'Accept': 'application/vnd.omisego.v1+json',
      'OMGAdmin-Account-ID': currentAccountId
    })
  })
})
