import { createFetcher } from '../utils/createFetcher'
import { getAccounts } from './action'
import { selectAccountsLoadingStatus, selectAccountsCachedQuery, selectAccounts } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('accounts', getAccounts, (state, props) => ({
  loadingStatus: selectAccountsLoadingStatus(state),
  data: selectAccountsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  accounts: selectAccounts(state)
}))
