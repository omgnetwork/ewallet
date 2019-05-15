import { usersReducer } from './reducer'

describe('users reducer', () => {
  test('should return the initial state', () => {
    expect(usersReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [USERS/REQUEST/SUCCESS]', () => {
    expect(
      usersReducer(
        {},
        {
          type: 'USERS/REQUEST/SUCCESS',
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
