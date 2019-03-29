import { walletsReducer } from './reducer'

describe('wallets reducer', () => {
  test('should return the initial state', () => {
    expect(walletsReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [WALLETS/REQUEST/SUCCESS]', () => {
    expect(
      walletsReducer(
        {},
        {
          type: 'WALLETS/REQUEST/SUCCESS',
          data: [{ address: '1', data: '1' }]
        }
      )
    ).toEqual({
      '1': {
        address: '1',
        data: '1'
      }
    })
  })
  test('should return the key by id object with action [USER_WALLETS/REQUEST/SUCCESS]', () => {
    expect(
      walletsReducer(
        {},
        {
          type: 'USER_WALLETS/REQUEST/SUCCESS',
          data: [{ address: '1', data: '1' }]
        }
      )
    ).toEqual({
      '1': {
        address: '1',
        data: '1'
      }
    })
  })
  test('should reset state when switch account', () => {
    expect(
      walletsReducer(
        {},
        {
          type: 'CURRENT_ACCOUNT/SWITCH'
        }
      )
    ).toEqual({})
  })
})
