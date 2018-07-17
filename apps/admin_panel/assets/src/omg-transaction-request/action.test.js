import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import {
  createTransactionRequest,
  getTransactionRequestById,
  getTransactionRequestConsumptions,
  getTransactionRequests,
  consumeTransactionRequest
} from './action'
import * as transactionRequestService from '../services/transactionRequestService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/transactionRequestService')
let store
describe('transactionRequest actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[createTransactionRequest] should dispatch success action if success to create transaction request', () => {
    transactionRequestService.createTransactionRequest.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'TRANSACTION_REQUEST/CREATE/INITIATED' },
      { type: 'TRANSACTION_REQUEST/CREATE/SUCCESS', data: { id: 'a' } }
    ]
    return store
      .dispatch(
        createTransactionRequest({
          type: 'type',
          tokenId: 'tokenId',
          amount: 'amount',
          correlationId: 'correlationId',
          address: 'address',
          accountId: 'accountId',
          providerUserId: 'providerUserId',
          requireConfirmation: 'requireConfirmation',
          maxConsumption: 'maxConsumption',
          maxConsumptionPerUser: 'maxConsumptionPerUser',
          expirationDate: 'expirationDate',
          allowAmountOverride: 'allowAmountOverride',
          consumptionLifetime: 'consumptionLifetime'
        })
      )
      .then(() => {
        expect(transactionRequestService.createTransactionRequest).toBeCalledWith({
          type: 'type',
          tokenId: 'tokenId',
          amount: 'amount',
          correlationId: 'correlationId',
          address: 'address',
          accountId: 'accountId',
          providerUserId: 'providerUserId',
          requireConfirmation: 'requireConfirmation',
          maxConsumption: 'maxConsumption',
          maxConsumptionPerUser: 'maxConsumptionPerUser',
          expirationDate: 'expirationDate',
          allowAmountOverride: 'allowAmountOverride',
          consumptionLifetime: 'consumptionLifetime'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[getTransactionRequestById] should dispatch success action if success to get transaction request', () => {
    transactionRequestService.consumeTransactionRequest.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'TRANSACTION_REQUEST/CONSUME/INITIATED' },
      { type: 'TRANSACTION_REQUEST/CONSUME/SUCCESS', data: { id: 'a' } }
    ]
    return store
      .dispatch(
        consumeTransactionRequest({
          formattedTransactionRequestId: 'formattedTransactionRequestId',
          correlationId: 'correlationId',
          tokenId: 'tokenId',
          amount: 'amount',
          providerUserId: 'providerUserId',
          address: 'address'
        })
      )
      .then(() => {
        expect(transactionRequestService.consumeTransactionRequest).toBeCalledWith({
          formattedTransactionRequestId: 'formattedTransactionRequestId',
          correlationId: 'correlationId',
          tokenId: 'tokenId',
          amount: 'amount',
          providerUserId: 'providerUserId',
          address: 'address'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getTransactionRequestById] should dispatch success action if success to get transaction request', () => {
    transactionRequestService.getTransactionRequestById.mockImplementation(() => {
      return Promise.resolve({ data: { data: { id: 'a' }, success: true } })
    })
    const expectedActions = [
      { type: 'TRANSACTION_REQUEST/REQUEST/INITIATED' },
      { type: 'TRANSACTION_REQUEST/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store.dispatch(getTransactionRequestById('id')).then(() => {
      expect(transactionRequestService.getTransactionRequestById).toBeCalledWith('id')
      expect(store.getActions()).toEqual(expectedActions)
    })
  })
  test('[getTransactionRequests] should dispatch success action if get transaction requests successfully', () => {
    transactionRequestService.getTransactionRequests.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'TRANSACTION_REQUESTS/REQUEST/INITIATED' },
      {
        type: 'TRANSACTION_REQUESTS/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(getTransactionRequests({ page: 1, perPage: 10, cacheKey: 'key' }))
      .then(() => {
        expect(transactionRequestService.getTransactionRequests).toBeCalledWith(
          expect.objectContaining({
            page: 1,
            perPage: 10,
            sort: { by: 'created_at', dir: 'desc' }
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
  test('[getTransactionRequestConsumptions] should dispatch success action if get transaction requests successfully', () => {
    transactionRequestService.getTransactionRequestConsumptions.mockImplementation(() => {
      return Promise.resolve({
        data: {
          success: true,
          data: { data: 'data', pagination: 'pagination' }
        }
      })
    })
    const expectedActions = [
      { type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/INITIATED' },
      {
        type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/SUCCESS',
        data: 'data',
        pagination: 'pagination',
        cacheKey: 'key'
      }
    ]
    return store
      .dispatch(
        getTransactionRequestConsumptions({ page: 1, perPage: 10, cacheKey: 'key', id: 'a' })
      )
      .then(() => {
        expect(transactionRequestService.getTransactionRequestConsumptions).toBeCalledWith(
          expect.objectContaining({
            id: 'a',
            page: 1,
            perPage: 10,
            sort: { by: 'created_at', dir: 'desc' }
          })
        )
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
})
