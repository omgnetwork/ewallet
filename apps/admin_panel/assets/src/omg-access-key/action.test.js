import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getAccessKeys, createAccessKey, deleteAccessKey, updateAccessKey } from './action'
import * as accessKeyService from '../services/accessKeyService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/accessKeyService')
let store
describe('apikeys actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[getAccessKeys] should dispatch success action if get access keys successfully', () => {
    accessKeyService.getAccessKeys.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'ACCESS_KEYS/REQUEST/INITIATED' },
      {
        type: 'ACCESS_KEYS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store.dispatch(getAccessKeys({ page: 1, perPage: 10, cacheKey: 'key' })).then(() => {
      expect(accessKeyService.getAccessKeys).toBeCalledWith(
        expect.objectContaining({
          page: 1,
          perPage: 10,
          sort: { by: 'created_at', dir: 'desc' }
        })
      )
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[createAccessKey] should dispatch success action if get account successfully', () => {
    accessKeyService.createAccessKey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'ACCESS_KEY/CREATE/INITIATED' },
      {
        type: 'ACCESS_KEY/CREATE/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(createAccessKey()).then(() => {
      expect(accessKeyService.createAccessKey).toBeCalled()
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[deleteApiKey] should dispatch success action if get account successfully', () => {
    accessKeyService.deleteAccessKeyById.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'ACCESS_KEY/DELETE/INITIATED' },
      {
        type: 'ACCESS_KEY/DELETE/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(deleteAccessKey('id')).then(() => {
      expect(accessKeyService.deleteAccessKeyById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[updateAccessKey] should dispatch success action if get account successfully', () => {
    accessKeyService.updateAccessKey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'ACCESS_KEY/UPDATE/INITIATED' },
      {
        type: 'ACCESS_KEY/UPDATE/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(updateAccessKey({ id: 'id', expired: true })).then(() => {
      expect(accessKeyService.updateAccessKey).toBeCalledWith({ id: 'id', expired: true })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
