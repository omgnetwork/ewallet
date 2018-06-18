import createReducer from '../reducer/createReducer'

export const walletsReducer = createReducer(
  {},
  {
    'WALLETS/REQUEST/SUCCESS': (state, action) => {
      return {...state, ..._.keyBy(action.wallets, 'address')}
    },
    'USER_WALLETS/REQUEST/SUCCESS': (state, action) => {
      return {...state, ..._.keyBy(action.wallets, 'address')}
    },
    'WALLET/REQUEST/SUCCESS': (state, { wallet }) => {
      return { ...state, ...{ [wallet.address]: wallet } }
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
