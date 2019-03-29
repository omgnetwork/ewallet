import { updateConfiguration } from './configurationService'
import * as apiService from '../services/apiService'
jest.mock('./apiService.js')
describe('configurationService', () => {
  test('it should omit null, undefined, Nan, 0, "" value out before sending', () => {
    apiService.authenticatedRequest.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true
        }
      })
    })
    return updateConfiguration({
      baseUrl: 'url',
      redirectUrlPrefixes: [],
      maxPerPage: null,
      minPasswordLength: undefined,
      senderEmail: NaN,
      smtpUsername: ''
    }).then(() => {
      expect(apiService.authenticatedRequest).toBeCalledWith({
        path: '/configuration.update',
        data: {
          base_url: 'url',
          redirect_url_prefixes: [],
          smtp_username: ''
        }
      })
    })
  })
})
