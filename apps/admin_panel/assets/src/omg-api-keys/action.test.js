import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getApiKeys, createApiKey, deleteApiKey, updateApiKey } from './action'
import * as apikeyService from '../services/apikeyService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/apikeyService')
let store
describe('apikeys actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[getApiKeys] should dispatch success action if get account successfully', () => {
    apikeyService.getAllApikey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'API_KEYS/REQUEST/INITIATED' },
      {
        type: 'API_KEYS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store.dispatch(getApiKeys({ page: 1, perPage: 10, cacheKey: 'key' })).then(() => {
      expect(apikeyService.getAllApikey).toBeCalledWith(
        expect.objectContaining({
          page: 1,
          perPage: 10,
          sort: { by: 'created_at', dir: 'desc' }
        })
      )
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[createApiKey] should dispatch success action if get account successfully', () => {
    apikeyService.createApikey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'API_KEY/CREATE/INITIATED' },
      {
        type: 'API_KEY/CREATE/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(createApiKey('owner')).then(() => {
      expect(apikeyService.createApikey).toBeCalledWith({ owner: 'owner' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[deleteApiKey] should dispatch success action if get account successfully', () => {
    apikeyService.deleteApiKeyById.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'API_KEY/DELETE/INITIATED' },
      {
        type: 'API_KEY/DELETE/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(deleteApiKey('id')).then(() => {
      expect(apikeyService.deleteApiKeyById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[deleteApiKey] should dispatch success action if get account successfully', () => {
    apikeyService.updateApiKey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'API_KEY/UPDATE/INITIATED' },
      {
        type: 'API_KEY/UPDATE/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(updateApiKey({ id: 'id', expired: true })).then(() => {
      expect(apikeyService.updateApiKey).toBeCalledWith({ id: 'id', expired: true })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
