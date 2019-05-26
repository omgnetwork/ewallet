import { createFetcher } from '../utils/createFetcher'
import { getTransactions, getUserTransactions } from './action'
import {
  selectTransactionsLoadingStatus,
  selectTransactionsCachedQuery
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'

const createTransactionFetcher = (action, key) =>
  createFetcher(key, action, (state, props) => ({
    loadingStatus: selectTransactionsLoadingStatus(state),
    data: selectTransactionsCachedQuery(state)(props.cacheKey),
    pagination: selectCachedQueryPagination(state)(props.cacheKey)
  }))

export default createTransactionFetcher(getTransactions, 'transactions')

export const UserTransactionFetcher = createTransactionFetcher(
  getUserTransactions,
  'user_transactions'
)
