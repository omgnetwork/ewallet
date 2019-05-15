import { createFetcher } from '../utils/createFetcher'
import { getTransactions } from './action'
import { selectTransactionsLoadingStatus, selectTransactionsCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('transactions', getTransactions, (state, props) => ({
  loadingStatus: selectTransactionsLoadingStatus(state),
  data: selectTransactionsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
