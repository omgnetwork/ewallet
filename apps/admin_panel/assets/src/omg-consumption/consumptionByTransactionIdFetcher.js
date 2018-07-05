import { createFetcher } from '../utils/createFetcher'
import { getTransactionRequestConsumptions } from '../omg-transaction-request/action'
import { selectConsumptionsCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher(
  'consumptionTransactionRequest',
  getTransactionRequestConsumptions,
  (state, props) => ({
    data: selectConsumptionsCachedQuery(state)(props.cacheKey),
    pagination: selectCachedQueryPagination(state)(props.cacheKey)
  })
)
