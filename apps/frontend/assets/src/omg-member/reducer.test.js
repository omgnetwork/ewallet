import { inviteListReducer } from './reducer'

describe('member invite reducer', () => {
  test('[inviteListReducer] should return the initial state', () => {
    expect(inviteListReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('[inviteListReducer] should return the key by id object with action [INVITE_LIST/REQUEST/SUCCESS]', () => {
    expect(
      inviteListReducer(
        {},
        {
          type: 'INVITE_LIST/REQUEST/SUCCESS',
          data: [{ id: '1', data: '1', user_id: 'a' }]
        }
      )
    ).toEqual({
      'a': {
        id: '1',
        data: '1',
        user_id: 'a'
      }
    })
  })

  test('[inviteListReducer] should merge state', () => {
    expect(
      inviteListReducer(
        {
          'a': {
            id: '2',
            data: '2',
            user_id: 'a'
          }
        },
        {
          type: 'INVITE_LIST/REQUEST/SUCCESS',
          data: [{ id: '1', data: '1', user_id: 'b' }]
        }
      )
    ).toEqual({
      'b': {
        id: '1',
        data: '1',
        user_id: 'b'
      },
      'a': {
        id: '2',
        data: '2',
        user_id: 'a'
      }
    })
  })
})
