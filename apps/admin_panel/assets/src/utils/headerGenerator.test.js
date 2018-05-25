import createHeaders from './headerGenerator'
import btoa from 'btoa'
describe('headerGenerator', () => {
  const adminApiKeyId = 'api_key_id'
  const adminApiKey = 'api_key'
  const currentAccountId = 'account_id'
  const accessToken = 'a very obfuscated dummy access token'
  test('function createHeaders should return correct header for [authenticated] request', () => {
    const header = createHeaders({
      auth: true,
      accessToken,
      adminApiKeyId,
      adminApiKey,
      currentAccountId
    })
    const AuthorizationEncoded = btoa(`${adminApiKeyId}:${adminApiKey}:${accessToken}`)
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
      adminApiKeyId,
      adminApiKey,
      currentAccountId
    })
    const AuthorizationEncoded = btoa(`${adminApiKeyId}:${adminApiKey}`)
    expect(header).toEqual({
      'Accept': 'application/vnd.omisego.v1+json',
      'Authorization': `OMGAdmin ${AuthorizationEncoded}`,
      'OMGAdmin-Account-ID': currentAccountId
    })
  })
  test('function createHeaders should return correct header when provide header options', () => {
    const header = createHeaders({
      auth: false,
      accessToken,
      adminApiKeyId,
      adminApiKey,
      currentAccountId,
      headerOption: {'Accept': 'OVERIDE'}
    })
    const AuthorizationEncoded = btoa(`${adminApiKeyId}:${adminApiKey}`)
    expect(header).toEqual({
      'Accept': 'OVERIDE',
      'Authorization': `OMGAdmin ${AuthorizationEncoded}`,
      'OMGAdmin-Account-ID': currentAccountId
    })
  })
})
