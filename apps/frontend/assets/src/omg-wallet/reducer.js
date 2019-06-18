import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const walletsReducer = createReducer(
  {},
  {
    'WALLETS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'address') }
    },
    'USER_WALLETS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'address') }
    },
    'WALLET/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.address]: data } }
    },
    'WALLET/CREATE/SUCCESS': (state, { data }) => {
      const byKey = { [data.address]: data }
      return { ...state, ...byKey }
    },
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)

export const walletsLoadingStatusReducer = createReducer('DEFAULT', {
  'WALLETS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'WALLETS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'WALLETS/REQUEST/FAILED': (state, action) => 'FAILED'
})
