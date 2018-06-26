export const selectAccounts = state => {
  return _.values(state.accounts) || []
}
export const selectAccountsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(accountId => {
    return selectGetAccountById(state)(accountId)
  })
}
export const selectAccountsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
export const selectAccountsLoadingStatus = state => state.accountsLoadingStatus
export const selectGetAccountById = state => id => state.accounts[id]
