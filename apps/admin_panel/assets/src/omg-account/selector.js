export const selectAccounts = state => {
  return _.values(state.accounts) || []
}
export const selectAccountsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(accountId => {
    return selectGetAccountById(state)(accountId)
  })
}
export const selectAccountsAllPagesCachedQuery = state => cacheKey => {
  const query = JSON.parse(cacheKey)
  const allAccountsInCache = new Array(query.page).fill().reduce((prev, curr, index) => {
    const newCacheKey = JSON.stringify({ ...query, page: index + 1 })
    const accounts = _.get(state.cacheQueries[newCacheKey], 'ids', [])
    accounts.forEach(accountId => {
      if (_.findIndex(prev, a => a.id === accountId) === -1) {
        prev.push(selectGetAccountById(state)(accountId))
      }
    })
    return prev
  }, [])
  return allAccountsInCache
}
export const selectAccountsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
export const selectAccountsLoadingStatus = state => state.accountsLoadingStatus
export const selectGetAccountById = state => id => state.accounts[id]
