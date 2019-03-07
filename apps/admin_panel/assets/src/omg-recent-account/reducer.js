import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const recentAccountsReducer = createReducer([], {
  'ACCOUNT/VISIT': (state, { accountId }) => {
    if (!_.includes(state, accountId)) {
      return [accountId, ...state].slice(0, 5)
    } else {
      return [accountId, ...state.filter(_accountId => _accountId !== accountId)]
    }
  }
})
