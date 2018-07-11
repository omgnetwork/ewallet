import { transactionsReducer } from './reducer'

describe('accounts reducer', () => {
  test('should return the initial state', () => {
    expect(transactionsReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [TRANSACTIONS/REQUEST/SUCCESS]', () => {
    expect(
      transactionsReducer(
        {},
        {
          type: 'TRANSACTIONS/REQUEST/SUCCESS',
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
  test('should return the key by id object with action [TRANSACTIONS/REQUEST/SUCCESS]', () => {
    expect(transactionsReducer({}, { type: 'CURRENT_ACCOUNT/SWITCH', data: { id: '1' } })).toEqual(
      {}
    )
  })
})
