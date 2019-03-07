import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const recentAccountsReducer = createReducer([], {
  'ACCOUNT/VISIT': (state, { accountId }) => {
    return [accountId, ...state]
  }
})
