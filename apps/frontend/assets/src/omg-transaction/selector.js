import { createSelectAllPagesCachedQuery } from '../omg-cache/selector'

export const selectTransactions = state => {
  return _.values(state.transactions)
}
export const selectNewTransactions = state => selectTransactions(state).filter(tx => tx.__new)

export const selectTransactionsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(transactionId => {
    return selectGetTransactionById(state)(transactionId)
  })
}

export const selectGetTransactionById = state => id => state.transactions[id] || {}

export const selectTransactionsLoadingStatus = state => state.loadingStatus.transactions

export const selectTransactionsAllPagesCachedQuery = createSelectAllPagesCachedQuery(
  selectGetTransactionById
)
