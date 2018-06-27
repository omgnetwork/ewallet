import { createFetcher } from '../utils/createFetcher'
import { getTokens } from './action'
import { selectTokensLoadingStatus, selectTokensAllPagesCachedQuery, selectTokensCachedQueryPagination } from './selector'
export default createFetcher('tokens', getTokens, (state, props) => ({
  loadingStatus: selectTokensLoadingStatus(state),
  data: selectTokensAllPagesCachedQuery(state)(props.cacheKey),
  pagination: selectTokensCachedQueryPagination(state)(props.cacheKey)
}))
