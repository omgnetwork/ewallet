import { apiKeysReducer } from './reducer'

describe('apikeys reducer', () => {
  test('should return the initial state', () => {
    expect(apiKeysReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [API_KEYS/REQUEST/SUCCESS]', () => {
    expect(
      apiKeysReducer(
        {},
        {
          type: 'API_KEYS/REQUEST/SUCCESS',
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
    expect(apiKeysReducer({}, { type: 'CURRENT_ACCOUNT/SWITCH' })).toEqual({})
  })
})
