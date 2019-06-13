import { createFetcher } from '../utils/createFetcher'
import { getTransactions, getUserTransactions } from './action'
import {
  selectTransactionsLoadingStatus,
  selectTransactionsCachedQuery
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'

const createTransactionFetcher = (key, action) =>
  createFetcher(key, action, (state, props) => ({
    loadingStatus: selectTransactionsLoadingStatus(state),
    data: selectTransactionsCachedQuery(state)(props.cacheKey),
    pagination: selectCachedQueryPagination(state)(props.cacheKey)
  }))

export default createTransactionFetcher('transactions', getTransactions)

export const UserTransactionFetcher = createTransactionFetcher(
  'user_transactions',
  getUserTransactions
)
