import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { createToken, mintToken, getMintedTokenHistory, getTokenById, getTokens } from './action'
import * as tokenService from '../services/tokenService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/tokenService')
let store
describe('account actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[createAccount] should dispatch failed action if fail to create account', () => {
    tokenService.createAccount.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' } } })
    })
    tokenService.uploadAccountAvatar.mockImplementation(() => {
      return Promise.resolve({ data: { success: false, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'ACCOUNT/CREATE/INITIATED' },
      { type: 'ACCOUNT/CREATE/FAILED', error: { id: 'a' } }
    ]
    return store
      .dispatch(
        createAccount({
          name: 'name',
          description: 'description',
          avatar: 'avatar',
          category: 'cat'
        })
      )
      .then(() => {
        expect(tokenService.createAccount).toBeCalledWith({
          name: 'name',
          description: 'description',
          category: 'cat'
        })
        expect(tokenService.uploadAccountAvatar).toBeCalledWith({
          accountId: 'a',
          avatar: 'avatar'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[createAccount] should dispatch success action if create account successfully', () => {
    tokenService.createAccount.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' } } })
    })
    tokenService.uploadAccountAvatar.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })

    const expectedActions = [
      { type: 'ACCOUNT/CREATE/INITIATED' },
      { type: 'ACCOUNT/CREATE/SUCCESS', data: { id: 'a' } }
    ]
    return store
      .dispatch(
        createAccount({
          name: 'name',
          description: 'description',
          avatar: 'avatar',
          category: 'cat'
        })
      )
      .then(() => {
        expect(tokenService.createAccount).toBeCalledWith({
          name: 'name',
          description: 'description',
          category: 'cat'
        })
        expect(tokenService.uploadAccountAvatar).toBeCalledWith({
          accountId: 'a',
          avatar: 'avatar'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getAccountById] should dispatch success action if get account successfully', () => {
    tokenService.getAccountById.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'ACCOUNT/REQUEST/INITIATED' },
      { type: 'ACCOUNT/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getAccountById({ id: 'a' })).then(() => {
      expect(tokenService.getAccountById).toBeCalledWith({
        id: 'a'
      })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[getAccountById] should dispatch failed action if get account unsuccessfully', () => {
    tokenService.getAccountById.mockImplementation(() => {
      return Promise.resolve({ data: { success: false, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'ACCOUNT/REQUEST/INITIATED' },
      { type: 'ACCOUNT/REQUEST/FAILED', error: { id: 'a' } }
    ]
    return store.dispatch(getAccountById({ id: 'a' })).then(() => {
      expect(tokenService.getAccountById).toBeCalledWith({
        id: 'a'
      })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[getAccounts] should dispatch success action if get account successfully', () => {
    tokenService.getAllAccounts.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'ACCOUNTS/REQUEST/INITIATED' },
      {
        type: 'ACCOUNTS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store.dispatch(getAccounts({ page: 1, perPage: 10, cacheKey: 'key' })).then(() => {
      expect(tokenService.getAllAccounts).toBeCalledWith(
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
