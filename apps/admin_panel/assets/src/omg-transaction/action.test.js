import configureMockStore from 'redux-mock-store'
import thunk from 'redux-thunk'
import { transfer, getTransactionById, getTransactions } from './action'
import * as transactionService from '../services/transactionService'
const middlewares = [thunk]
const mockStore = configureMockStore(middlewares)
jest.mock('../services/transactionService')
let store
describe('account actions', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    store = mockStore()
  })
  test('[transfer] should dispatch correct action if successfully tranfer', () => {
    transactionService.transfer.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'TRANSACTION/CREATE/INITIATED' },
      { type: 'TRANSACTION/CREATE/SUCCESS', data: { id: 'a' } }
    ]
    return store
      .dispatch(
        transfer({
          fromAddress: 'fromAddress',
          toAddress: 'toAddress',
          tokenId: 'tokenId',
          fromTokenId: 'fromTokenId',
          toTokenId: 'toTokenId',
          fromAmount: '100',
          toAmount: '100',
          amount: 'amount',
          exchangeAddress: 'exchangeAddress'
        })
      )
      .then(() => {
        expect(transactionService.transfer).toBeCalledWith({
          fromAddress: 'fromAddress',
          toAddress: 'toAddress',
          tokenId: 'tokenId',
          fromTokenId: 'fromTokenId',
          toTokenId: 'toTokenId',
          fromAmount: '100',
          toAmount: '100',
          amount: 'amount',
          exchangeAddress: 'exchangeAddress'
        })
        expect(store.getActions()).toEqual(expectedActions)
      })
  })

  test('[getTransactionById] should dispatch correct action if successfully get transaction', () => {
    transactionService.getTransactionById.mockImplementation(() => {
      return Promise.resolve({ data: { success: true, data: { id: 'a' } } })
    })
    const expectedActions = [
      { type: 'TRANSACTION/REQUEST/INITIATED' },
      { type: 'TRANSACTION/REQUEST/SUCCESS', data: { id: 'a' } }
    ]
    return store
      .dispatch(
        getTransactionById('acc')
      )
      .then(() => {
        expect(transactionService.getTransactionById).toBeCalledWith('acc')
        expect(store.getActions()).toEqual(expectedActions)
      })
  })
})
