import { selectGetAccountById } from '../omg-account/selector'
import _ from 'lodash'
export const selectRecentAccounts = state =>
  state.recentAccounts
    .filter(maybeExistRecentAccountId => selectGetAccountById(state)(maybeExistRecentAccountId))
    .map((recentAccountId, i) => {
      const account = selectGetAccountById(state)(recentAccountId)
      return account.injected_loading ? { ...account, name: '...' } : account
    })
