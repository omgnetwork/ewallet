import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const recentAccountsReducer = createReducer([], {
  'ACCOUNT/VISIT': (state, { accountId }) => {
    if (!_.includes(state, accountId)) {
      return [accountId, ...state].slice(0, 5)
    } else {
      return state
    }
  },
  'ACCOUNT/DELETE': (state, { data }) => {
    return state.filter(accountId => accountId !== data)
  }
})
