import createReducer from '../reducer/createReducer'
export const currentAccountReducer = createReducer({}, {
  'LOGIN/SUCCESS': (state, { currentAccount }) => {
    return currentAccount
  },
  'CURRENT_ACCOUNT/REQUEST/SUCCESS': (state, { currentAccount }) => {
    return currentAccount
  },
  'CURRENT_ACCOUNT/UPDATE/SUCCESS': (state, { currentAccount }) => {
    return currentAccount
  },
  'CURRENT_ACCOUNT/SWITCH': (state, { currentAccount }) => {
    return currentAccount
  }
})

export const currentAccountLoadingStatusReducer = createReducer('DEFAULT', {
  'CURRENT_ACCOUNT/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'CURRENT_ACCOUNT/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_ACCOUNT/REQUEST/FAILED': (state, action) => 'FAILED'
})
