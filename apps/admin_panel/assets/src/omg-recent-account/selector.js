import { selectGetAccountById } from '../omg-account/selector'
import _ from 'lodash'
export const selectRecentAccounts = state => {
  return _.compact(
    state.recentAccounts.map(
      (accountId, i) => selectGetAccountById(state)(accountId) || { name: '...' }
    )
  )
}
