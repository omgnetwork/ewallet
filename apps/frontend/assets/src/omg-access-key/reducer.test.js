import { accessKeysReducer } from './reducer'

describe('accessKeys reducer', () => {
  test('should return the initial state', () => {
    expect(accessKeysReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [ACCESS_KEYS/REQUEST/SUCCESS]', () => {
    expect(
      accessKeysReducer(
        {},
        {
          type: 'ACCESS_KEYS/REQUEST/SUCCESS',
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
  test('should reset state when receive action [CURRENT_ACCOUNT/SWITCH]', () => {
    expect(accessKeysReducer({}, { type: 'CURRENT_ACCOUNT/SWITCH' })).toEqual({})
  })
})
