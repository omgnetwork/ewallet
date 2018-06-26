export const selectAccounts = (state, search) => {
  return _.values(state.accounts)
  .filter(x => {
    const reg = new RegExp(search)
    return reg.test(x.name) || reg.test(x.description)
  })
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
