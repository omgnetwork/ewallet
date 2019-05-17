import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getApiKeys, getApiKey, createApiKey, deleteApiKey, updateApiKey, enableApiKey } from './action'
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
  test('[getApiKeys] should dispatch success action if get key successfully', () => {
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
  test('[createApiKey] should dispatch success action if create key successfully', () => {
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
    return store.dispatch(createApiKey({ name: 'PRAYUTHHHHHHHHHHHHHHH' })).then(() => {
      expect(apikeyService.createApikey).toBeCalledWith({
        name: 'PRAYUTHHHHHHHHHHHHHHH'
      })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[deleteApiKey] should dispatch success action if delete key successfully', () => {
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

  test('[updateApiKey] should dispatch success action if update key successfully', () => {
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
    return store.dispatch(updateApiKey({ id: 'id', name: 'toto' })).then(() => {
      expect(apikeyService.updateApiKey).toBeCalledWith({ id: 'id', name: 'toto' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[enableApiKey] should dispatch success action if enable key successfully', () => {
    apikeyService.enableApiKey.mockImplementation(() => {
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
    return store.dispatch(enableApiKey({ id: 'id', enabled: true })).then(() => {
      expect(apikeyService.enableApiKey).toBeCalledWith({ id: 'id', enabled: true })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[getApiKey] should dispatch success action if get key successfully', () => {
    apikeyService.getApiKey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'API_KEY/REQUEST/INITIATED' },
      {
        type: 'API_KEY/REQUEST/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(getApiKey('id')).then(() => {
      expect(apikeyService.getApiKey).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
