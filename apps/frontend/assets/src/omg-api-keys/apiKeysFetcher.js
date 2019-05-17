import { createFetcher } from '../utils/createFetcher'
import { getApiKeys } from './action'
import { selectCachedQueryPagination } from '../omg-cache/selector'
import { selectApiKeysLoadingStatus, selectApiKeysCachedQuery } from './selector'
export default createFetcher('apiKeys', getApiKeys, (state, props) => ({
  loadingStatus: selectApiKeysLoadingStatus(state),
  data: selectApiKeysCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
