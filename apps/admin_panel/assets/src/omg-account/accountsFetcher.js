import { createFetcher } from '../utils/createFetcher'
import { getAccounts } from './action'
import {
  selectAccountsLoadingStatus,
  selectAccountsCachedQuery,
  selectAccountsCachedQueryPagination
} from './selector'
export default createFetcher('accounts', getAccounts, (state, props) => ({
  loadingStatus: selectAccountsLoadingStatus(state),
  data: selectAccountsCachedQuery(state)(props.cacheKey),
  pagination: selectAccountsCachedQueryPagination(state)(props.cacheKey)
}))
