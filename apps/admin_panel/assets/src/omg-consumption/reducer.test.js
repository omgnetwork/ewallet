import { consumptionsReducer } from './reducer'

describe('consumptions reducer', () => {
  test('should return the initial state', () => {
    expect(consumptionsReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [CONSUMPTIONS/REQUEST/SUCCESS]', () => {
    expect(
      consumptionsReducer(
        {},
        {
          type: 'CONSUMPTIONS/REQUEST/SUCCESS',
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
