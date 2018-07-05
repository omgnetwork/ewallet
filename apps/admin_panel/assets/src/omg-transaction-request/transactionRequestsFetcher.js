import { createFetcher } from '../utils/createFetcher'
import { getTransactionRequests } from './action'
import {
  selectTransactionRequestsLoadingStatus,
  selectTransactionRequestsCachedQuery,
  selectTransactionRequests
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('transactionRequest', getTransactionRequests, (state, props) => ({
  loadingStatus: selectTransactionRequestsLoadingStatus(state),
  data: selectTransactionRequestsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  TransactionRequests: selectTransactionRequests(state)
}))
