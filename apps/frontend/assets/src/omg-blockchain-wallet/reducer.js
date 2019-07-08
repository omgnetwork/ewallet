import _ from 'lodash'

import createReducer from '../reducer/createReducer'

export const blockchainWalletReducer = createReducer(
  {},
  {
    'BLOCKCHAIN_WALLET_BALANCES/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'BLOCKCHAIN_WALLET/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'BLOCKCHAIN_WALLETS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    }
  }
)
