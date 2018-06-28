export const selectTransactions = (state, search) => {
  return _.values(state.transactions).filter(x => {
    const reg = new RegExp(search)
    return (
      reg.test(x.id) ||
      reg.test(x.status) ||
      reg.test(x.from.token.symbol) ||
      reg.test(x.to.token.symbol)
    )
  })
}
export const selectTransactionsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(transactionId => {
    return selectGetTransactionById(state)(transactionId)
  })
}
export const selectTransactionsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
export const selectGetTransactionById = state => id => state.transactions[id]
export const selectTransactionsLoadingStatus = state => state.transactionsLoadingStatus
