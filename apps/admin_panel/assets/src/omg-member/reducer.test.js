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

  test('[inviteListReducer] should merge state', () => {
    expect(
      inviteListReducer(
        {
          '2': {
            id: '2',
            data: '2'
          }
        },
        {
          type: 'INVITE_LIST/REQUEST/SUCCESS',
          data: [{ id: '1', data: '1' }]
        }
      )
    ).toEqual({
      '1': {
        id: '1',
        data: '1'
      },
      '2': {
        id: '2',
        data: '2'
      }
    })
  })
})
