import _ from 'lodash'

import createReducer from '../reducer/createReducer'

export const blockchainWalletReducer = createReducer(
  {},
  {
    'BLOCKCHAIN_WALLET/CREATE/SUCCESS': (state, action) => {
      return { ...state, [action.data.address]: action.data }
    },
    'BLOCKCHAIN_WALLET/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'address') }
    },
    'BLOCKCHAIN_WALLETS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'address') }
    }
  }
)

export const plasmaDepositReducer = createReducer(
  {},
  {
    'BLOCKCHAIN_WALLET/DEPOSIT/SUCCESS': (state, action) => {
      return { ...state, [action.data.from_blockchain_address]: action.data }
    }
  }
)

export const blockchainWalletBalanceReducer = createReducer(
  {},
  {
    'BLOCKCHAIN_WALLET_BALANCE/REQUEST/SUCCESS': (state, action) => {
      const [rootBalance, plasmaBalance] = action.data
      const balances = rootBalance.map(balance => {
        const fromPlasma = plasmaBalance.find(i => i.token.id === balance.token.id)
        return {
          ...balance,
          plasmaAmount: fromPlasma.amount
        }
      })
      const request = typeof action.cacheKey === 'string'
        ? JSON.parse(action.cacheKey)
        : action.cacheKey
      return { ...state, [request.address]: balances }
    }
  }
)
