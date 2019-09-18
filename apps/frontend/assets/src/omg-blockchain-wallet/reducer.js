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

export const blockchainWalletBalanceReducer = createReducer(
  {},
  {
    'BLOCKCHAIN_WALLET_BALANCE/REQUEST/SUCCESS': (state, action) => {
      const request = JSON.parse(action.cacheKey)
      return { ...state, [request.address]: action.data }
    }
  }
)
