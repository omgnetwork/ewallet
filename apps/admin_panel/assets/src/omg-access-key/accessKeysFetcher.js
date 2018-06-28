import { createFetcher } from '../utils/createFetcher'
import { getAccessKeys } from './action'
import { selectCachedQueryPagination } from '../omg-cache/selector'
import { selectAccessKeysLoadingStatus, selectAccessKeysCachedQuery } from './selector'
export default createFetcher('accessKeys', getAccessKeys, (state, props) => ({
  loadingStatus: selectAccessKeysLoadingStatus(state),
  data: selectAccessKeysCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
