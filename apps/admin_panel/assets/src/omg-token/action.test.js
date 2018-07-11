import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { createToken, mintToken, getMintedTokenHistory, getTokenById, getTokens } from './action'
import * as tokenService from '../services/tokenService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/tokenService')
let store
describe('token actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[createToken] should dispatch success action if successfully create token', () => {
    tokenService.createToken.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: 'data' } })
    })
    const expectedActions = [
      { type: 'TOKEN/CREATE/INITIATED' },
      { type: 'TOKEN/CREATE/SUCCESS', data: 'data' }
    ]
    return store
      .dispatch(createToken({ name: 'name', symbol: 'symbol', decimal: 'decimal', amount: '50' }))
      .then(() => {
        expect(tokenService.createToken).toBeCalledWith({
          name: 'name',
          symbol: 'symbol',
          decimal: 'decimal',
          amount: '50'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[mintToken] should dispatch success action if successfully mintToken', () => {
    tokenService.mintToken.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: 'data' } })
    })
    const expectedActions = [
      { type: 'TOKEN/MINT/INITIATED' },
      { type: 'TOKEN/MINT/SUCCESS', data: 'data' }
    ]
    return store.dispatch(mintToken({ id: 'id', amount: '50' })).then(() => {
      expect(tokenService.mintToken).toBeCalledWith({ id: 'id', amount: '50' })
      expect(store.getActions()).toEqual(expectedActions)
    })
  })

  test('[getMintedTokenHistory] should dispatch success action if successfully getMintedTokenHistory', () => {
    tokenService.getMintedTokenHistory.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'TOKEN_HISTORY/REQUEST/INITIATED' },
      {
        type: 'TOKEN_HISTORY/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getMintedTokenHistory({ page: 1, perPage: 10, cacheKey: 'key', search: 'search' }))
      .then(() => {
        expect(tokenService.getMintedTokenHistory).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            sort: { by: 'created_at', dir: 'desc' },
            search: 'search'
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getTokens] should dispatch success action if successfully getTokens', () => {
    tokenService.getAllTokens.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'TOKENS/REQUEST/INITIATED' },
      {
        type: 'TOKENS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getTokens({ page: 1, perPage: 10, cacheKey: 'key', search: 'search' }))
      .then(() => {
        expect(tokenService.getAllTokens).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            sort: { by: 'created_at', dir: 'desc' },
            search: 'search'
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getTokenById] should dispatch success action if successfully getTokenById', () => {
    tokenService.getTokenStatsById.mockImplementation(() => {
      return Promise.resolve({
        data: { success: true, data: { token: { id: '1' }, total_supply: 1 } }
      })
    })
    const expectedActions = [
      { type: 'TOKEN/REQUEST/INITIATED' },
      { type: 'TOKEN/REQUEST/SUCCESS', data: { token: { id: '1' }, total_supply: 1 } }
    ]
    return store.dispatch(getTokenById('id')).then(() => {
      expect(tokenService.getTokenStatsById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
})
