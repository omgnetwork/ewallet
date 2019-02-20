import { selectPrimaryWalletByAccountId } from './selector'

describe('selectors wallet', () => {
  test('should select primary wallet of current account', () => {
    const state = {
      accounts: { id: 'a' },
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
    expect(selectPrimaryWalletByAccountId(state)('a')).toEqual({
      account_id: 'a',
      identifier: 'primary'
    })
  })
})
