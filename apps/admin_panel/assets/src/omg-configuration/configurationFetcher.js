import { createFetcher } from '../utils/createFetcher'
import { getConfiguration } from './action'
import {
  selectConfigurationsCachedQuery,
  selectConfigurationsCachedQueryPagination
} from './selector'
export default createFetcher('configurations', getConfiguration, (state, props) => ({
  data: selectConfigurationsCachedQuery(state)(props.cacheKey),
  pagination: selectConfigurationsCachedQueryPagination(state)(props.cacheKey)
}))
