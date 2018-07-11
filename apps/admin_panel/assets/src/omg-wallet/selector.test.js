import { selectPrimaryWalletCurrentAccount } from './selector'

describe('selectors wallet', () => {
  test('should select primary wallet of current account', () => {
    const state = {
      currentAccount: { id: 'a' },
      wallets: {
        b: {
          account_id: 'a',
          identifier: 'primary'
        },
        c: {
          account_id: 'a',
          identifier: 'burn'
        }
      }
    }
    expect(selectPrimaryWalletCurrentAccount(state)).toEqual({
      account_id: 'a',
      identifier: 'primary'
    })
  })
})
