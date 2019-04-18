import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'
import { adminRequest } from './apiService'
import { ADMIN_API_URL } from '../config'
const mock = new MockAdapter(axios)
describe('apiService', () => {
  afterEach(() => {
    mock.reset()
  })
  test('request should be called successfully.', async () => {
    mock.onPost(`${ADMIN_API_URL}/testPath`).reply(200, {
      test: 'test'
    })
    const result = await adminRequest({
      path: '/testPath',
      data: { test: 'test' },
      headers: { duumyHeader: 'header' }
    })
    expect(result.status).toEqual(200)
    expect(result.data).toEqual({ test: 'test' })
  })
})
