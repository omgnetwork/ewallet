import { createFetcher } from '../utils/createFetcher'
import { getExchangePairs } from './action'
import { selectExchangePairCachedQuery, selectUsersCachedQueryPagination } from './selector'
export default createFetcher('exchange_pairs', getExchangePairs, (state, props) => ({
  data: selectExchangePairCachedQuery(state)(props.cacheKey),
  pagination: selectUsersCachedQueryPagination(state)(props.cacheKey)
}))
