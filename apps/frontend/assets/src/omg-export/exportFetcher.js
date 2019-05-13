import { createFetcher } from '../utils/createFetcher'
import { getExports } from './action'
import { selectExportsCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'

export default createFetcher('exports', getExports, (state, props) => ({
  data: selectExportsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
