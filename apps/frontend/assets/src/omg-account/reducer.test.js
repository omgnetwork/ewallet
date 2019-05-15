import { accountsReducer } from './reducer'

describe('accounts reducer', () => {
  test('should return the initial state', () => {
    expect(accountsReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [ACCOUNTS/REQUEST/SUCCESS]', () => {
    expect(
      accountsReducer(
        {},
        {
          type: 'ACCOUNTS/REQUEST/SUCCESS',
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
