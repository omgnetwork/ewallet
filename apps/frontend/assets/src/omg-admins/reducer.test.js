import { adminsReducer } from './reducer'

describe('admins reducer', () => {
  test('should return the initial state', () => {
    expect(adminsReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('should return the key by id object with action [ADMINS/REQUEST/SUCCESS]', () => {
    expect(
      adminsReducer(
        {},
        {
          type: 'ADMINS/REQUEST/SUCCESS',
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
