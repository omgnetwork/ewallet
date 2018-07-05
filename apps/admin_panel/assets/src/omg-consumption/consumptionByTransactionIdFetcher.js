import { createFetcher } from '../utils/createFetcher'
import { getTransactionRequestConsumptions } from '../omg-transaction-request/action'
import { selectConsumptionsCachedQuery, selectPendingConsumptions } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher(
  'consumptionTransactionRequest',
  getTransactionRequestConsumptions,
  (state, props) => ({
    data: selectConsumptionsCachedQuery(state)(props.cacheKey),
    pendingConsumption: selectPendingConsumptions(props.id)(state),
    pagination: selectCachedQueryPagination(state)(props.cacheKey)
  })
)
