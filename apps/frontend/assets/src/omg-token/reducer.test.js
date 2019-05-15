import { tokensReducer, mintedTokenHistoryReducer } from './reducer'

describe('tokens reducer', () => {
  test('[tokensReducer] should return the initial state', () => {
    expect(tokensReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('[mintedTokenHistoryReducer] should return the initial state', () => {
    expect(mintedTokenHistoryReducer({}, 'FAKE_ACTION')).toEqual({})
  })
  test('[tokensReducer] should return the key by id object with action [TOKENS/REQUEST/SUCCESS]', () => {
    expect(
      tokensReducer(
        {},
        {
          type: 'TOKENS/REQUEST/SUCCESS',
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
  test('[tokensReducer] should merge and keep total supply key', () => {
    expect(
      tokensReducer(
        { '1': { id: '1', data: '1', total_supply: '1' } },
        {
          type: 'TOKENS/REQUEST/SUCCESS',
          data: [{ id: '1', data: '1' }]
        }
      )
    ).toEqual({
      '1': {
        id: '1',
        data: '1',
        total_supply: '1'
      }
    })
  })
  test('[mintedTokenHistoryReducer] should return the key by id object with action [TOKEN_HISTORY/REQUEST/SUCCESS]', () => {
    expect(
      mintedTokenHistoryReducer(
        {},
        {
          type: 'TOKEN_HISTORY/REQUEST/SUCCESS',
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
  test('[tokensReducer] should inject total_supply and increse it with action [TOKEN/MINT/SUCCESS]', () => {
    expect(
      tokensReducer(
        { '1': { total_supply: 1 } },
        {
          type: 'TOKEN/MINT/SUCCESS',
          data: { token: { id: '1' }, amount: 1 }
        }
      )
    ).toEqual({
      '1': {
        total_supply: 2,
        id: '1'
      }
    })
  })
})
