import createReducer from '../reducer/createReducer'
import _ from 'lodash'
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
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)

export const walletsLoadingStatusReducer = createReducer('DEFAULT', {
  'WALLETS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'WALLETS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'WALLETS/REQUEST/FAILED': (state, action) => 'FAILED',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
