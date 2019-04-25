import { selectPrimaryWalletByAccountId } from './selector'

describe('selectors wallet', () => {
  test('should select primary wallet of current account', () => {
    const state = {
      accounts: { 'a': { id: 'a' } },
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

    const primaryWallet = selectPrimaryWalletByAccountId(state)('a')
    expect(primaryWallet).toEqual({
      account_id: 'a',
      identifier: 'primary'
    })
  })
})
