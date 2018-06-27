import { createFetcher } from '../utils/createFetcher'
import { getTransactions } from './action'
import { selectTransactionsLoadingStatus, selectTransactionsAllPagesCachedQuery, selectTransactionsCachedQueryPagination } from './selector'
export default createFetcher('transactions', getTransactions, (state, props) => ({
  loadingStatus: selectTransactionsLoadingStatus(state),
  data: selectTransactionsAllPagesCachedQuery(state)(props.cacheKey),
  pagination: selectTransactionsCachedQueryPagination(state)(props.cacheKey)
}))
