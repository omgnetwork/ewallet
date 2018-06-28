export const selectTransactionRequests = state => {
  return _.values(state.TransactionRequests) || []
}
export const selectTransactionRequestsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(id => {
    return selectGetTransactionRequestById(state)(id)
  })
}

export const selectGetTransactionRequestById = state => id => state.transactionRequests[id]

export const selectTransactionRequestsLoadingStatus = state => state.transactionRequestsLoadingStatus

