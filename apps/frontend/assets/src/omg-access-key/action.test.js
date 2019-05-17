import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getAccessKeys, getAccessKeyMemberships, createAccessKey, deleteAccessKey, getAccessKey, updateAccessKey } from './action'
import * as accessKeyService from '../services/accessKeyService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/accessKeyService')
let store
describe('accesskeys actions', () => {
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
  test('[createAccessKey] should dispatch success action if create key successfully', () => {
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
    return store.dispatch(createAccessKey({ name: 'PRAYUTHHHHHHHHHHHHHHH' })).then(() => {
      expect(accessKeyService.createAccessKey).toBeCalledWith({ name: 'PRAYUTHHHHHHHHHHHHHHH' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[deleteAccessKey] should dispatch success action if delete key successfully', () => {
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

  test('[getAccessKey] should dispatch success action if get key successfully', () => {
    accessKeyService.getAccessKey.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: 'key'
        }
      })
    })
    const expectedActions = [
      { type: 'ACCESS_KEY/REQUEST/INITIATED' },
      {
        type: 'ACCESS_KEY/REQUEST/SUCCESS',
        data: 'key'
      }
    ]
    return store.dispatch(getAccessKey('id')).then(() => {
      expect(accessKeyService.getAccessKey).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[getAccessKeyMemberships] should dispatch success action if get access key memberships successfully', () => {
    accessKeyService.getAccessKeyMemberships.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'ACCESS_KEY_MEMBERSHIPS/REQUEST/INITIATED' },
      {
        type: 'ACCESS_KEY_MEMBERSHIPS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store.dispatch(getAccessKeyMemberships({ perPage: 10, cacheKey: 'key' })).then(() => {
      expect(accessKeyService.getAccessKeyMemberships).toBeCalledWith(
        expect.objectContaining({
          perPage: 10,
          sortBy: 'created_at',
          sortDir: 'desc'
        })
      )
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[updateAccessKey] should dispatch success action if update key successfully', () => {
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
    return store.dispatch(updateAccessKey({ id: 'id', name: 'toto', globalRole: 'Admin' })).then(() => {
      expect(accessKeyService.updateAccessKey).toBeCalledWith({ id: 'id', name: 'toto', globalRole: 'Admin' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
