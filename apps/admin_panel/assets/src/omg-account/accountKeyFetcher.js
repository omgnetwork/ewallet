import { createFetcher } from '../utils/createFetcher'
import { getKeysAccountId } from './action'
import { selectCachedQueryPagination } from '../omg-cache/selector'
import { selectAccessKeysCachedQuery } from '../omg-access-key/selector'

export default createFetcher('accessKeys', getKeysAccountId, (state, props) => ({
  data: selectAccessKeysCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
