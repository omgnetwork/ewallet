import createReducer from '../reducer/createReducer'

export const walletsReducer = createReducer(
  {},
  {
    'WALLETS/REQUEST/SUCCESS': (state, action) => {
      return _.keyBy(action.wallets, 'address')
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
