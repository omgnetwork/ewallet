import { selectGetAccountByIdMaybeLoading } from '../omg-account/selector'
export const selectRecentAccounts = state =>
  state.recentAccounts
    .filter(maybeExistRecentAccountId =>
      selectGetAccountByIdMaybeLoading(state)(maybeExistRecentAccountId)
    )
    .map((recentAccountId, i) => {
      const account = selectGetAccountByIdMaybeLoading(state)(recentAccountId)
      return account.injected_loading ? { ...account, name: '...' } : account
    })
