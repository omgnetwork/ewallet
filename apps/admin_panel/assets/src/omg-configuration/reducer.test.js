import { configurationReducer } from './reducer'

describe('configurations reducer', () => {
  test('should return the initial state', () => {
    expect(configurationReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [CONFIGURATIONS/REQUEST/SUCCESS]', () => {
    expect(
      configurationReducer(
        {},
        {
          type: 'CONFIGURATIONS/REQUEST/SUCCESS',
          data: {
            data: [{ id: '1', data: '1', key: 'x' }]
          }
        }
      )
    ).toEqual({
      x: {
        id: '1',
        data: '1',
        key: 'x'
      }
    })
  })
})
