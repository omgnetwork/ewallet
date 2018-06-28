import { createFetcher } from '../utils/createFetcher'
import { getTransactions } from './action'
import { selectTransactionsLoadingStatus, selectTransactionsCachedQuery, selectTransactionsCachedQueryPagination } from './selector'
export default createFetcher('transactions', getTransactions, (state, props) => ({
  loadingStatus: selectTransactionsLoadingStatus(state),
  data: selectTransactionsCachedQuery(state)(props.cacheKey),
  pagination: selectTransactionsCachedQueryPagination(state)(props.cacheKey)
}))
