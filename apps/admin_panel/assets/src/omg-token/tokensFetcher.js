import { createFetcher } from '../utils/createFetcher'
import { getTokens } from './action'
import { selectTokensLoadingStatus, selectTokensCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('tokens', getTokens, (state, props) => ({
  loadingStatus: selectTokensLoadingStatus(state),
  data: selectTokensCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
