import { createFetcher } from '../utils/createFetcher'
import { getConfiguration } from './action'
import {
  selectConfigurationsCachedQuery,
  selectConfigurationsCachedQueryPagination
} from './selector'
export default createFetcher('wallets', getConfiguration, (state, props) => ({
  data: selectConfigurationsCachedQuery(state)(props.cacheKey),
  pagination: selectConfigurationsCachedQueryPagination(state)(props.cacheKey)
}))
