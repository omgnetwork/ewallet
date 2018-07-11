import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { getWalletsByAccountId, getWalletsByUserId, getWalletById, getWallets } from './action'
import * as walletService from '../services/walletService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/walletService')
let store
describe('account actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })

  test('[getWalletById] should dispatch failed action if get account unsuccessfully', () => {
    walletService.getWallet.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'WALLET/REQUEST/INITIATED' },
      { type: 'WALLET/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getWalletById({ id: 'a' })).then(() => {
      expect(walletService.getWallet).toBeCalledWith({
        id: 'a'
      })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[getWallets] should dispatch success action if get account successfully', () => {
    walletService.getWallets.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'WALLETS/REQUEST/INITIATED' },
      {
        type: 'WALLETS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getWallets({ page: 1, perPage: 10, cacheKey: 'key', search: 'search' }))
      .then(() => {
        expect(walletService.getWallets).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            search: 'search',
            sort: { by: 'created_at', dir: 'desc' }
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[getWalletsByAccountId] should dispatch success action if get account successfully', () => {
    walletService.getWalletsByAccountId.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'WALLETS/REQUEST/INITIATED' },
      {
        type: 'WALLETS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getWalletsByAccountId({ page: 1, perPage: 10, cacheKey: 'key' }))
      .then(() => {
        expect(walletService.getWalletsByAccountId).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            sort: { by: 'created_at', dir: 'desc' }
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[getWalletsByUserId] should dispatch success action if get account successfully', () => {
    walletService.getWalletsByUserId.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'USER_WALLETS/REQUEST/INITIATED' },
      {
        type: 'USER_WALLETS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getWalletsByUserId({ page: 1, perPage: 10, cacheKey: 'key' }))
      .then(() => {
        expect(walletService.getWalletsByUserId).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            sort: { by: 'created_at', dir: 'desc' }
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
})
