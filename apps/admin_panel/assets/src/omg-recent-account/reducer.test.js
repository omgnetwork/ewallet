import { recentAccountsReducer } from './reducer'

describe('recent account reducer', () => {
  test('[recentAccountsReducer] should return the initial state', () => {
    expect(recentAccountsReducer([], 'FAKE_ACTION')).toEqual([])
  })
  test('[recentAccountsReducer] should array account that just visited', () => {
    expect(
      recentAccountsReducer([], {
        type: 'ACCOUNT/VISIT',
        accountId: 'account-id-1'
      })
    ).toEqual(['account-id-1'])
  })
  test('[recentAccountsReducer] should array account that just visited and put infront if not visited yet', () => {
    expect(
      recentAccountsReducer(['account-id-2'], {
        type: 'ACCOUNT/VISIT',
        accountId: 'account-id-1'
      })
    ).toEqual(['account-id-1', 'account-id-2'])
  })
})
