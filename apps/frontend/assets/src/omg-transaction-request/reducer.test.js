import { transactionRequestsReducer } from './reducer'
import { consumptionsReducer } from '../omg-consumption/reducer'
describe('transaction requests reducer', () => {
  test('should return the initial state', () => {
    expect(transactionRequestsReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [TRANSACTION_REQUESTS/REQUEST/SUCCESS]', () => {
    expect(
      transactionRequestsReducer(
        {},
        {
          type: 'TRANSACTION_REQUESTS/REQUEST/SUCCESS',
          data: [{ id: '1', data: '1' }]
        }
      )
    ).toEqual({
      '1': {
        id: '1',
        data: '1'
      }
    })
  })
  test('should return the key by id object with action [TRANSACTION_REQUEST_CONSUMPTION/REQUEST/SUCCESS]', () => {
    expect(
      consumptionsReducer(
        {},
        {
          type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/SUCCESS',
          data: [{ id: '1', data: '1' }]
        }
      )
    ).toEqual({
      '1': {
        id: '1',
        data: '1'
      }
    })
  })
})
