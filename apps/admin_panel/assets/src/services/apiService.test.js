import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'
import { request } from './apiService'
import { ADMIN_API_BASE_URL } from '../../config'
const mock = new MockAdapter(axios)
describe('apiService', () => {
  afterEach(() => {
    mock.reset()
  })
  test('request should be called with base url', async () => {
    mock.onPost(`${ADMIN_API_BASE_URL}/testPath`).reply(200, {
      test: 'test'
    })
    const result = await request({ path: '/testPath', data: { test: 'test' }, headers: { duumyHeader: 'header' } })
    expect(result.status).toEqual(200)
    expect(result.data).toEqual({ test: 'test' })
  })
})
