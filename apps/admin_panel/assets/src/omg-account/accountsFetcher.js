import { createFetcher } from '../utils/createFetcher'
import { getAccounts } from './action'
import {
  selectAccountsLoadingStatus,
  selectAccountsAllPagesCachedQuery,
  selectAccountsCachedQueryPagination,
  selectAccounts
} from './selector'
export default createFetcher('accounts', getAccounts, (state, props) => ({
  loadingStatus: selectAccountsLoadingStatus(state),
  data: selectAccountsAllPagesCachedQuery(state)(props.cacheKey),
  pagination: selectAccountsCachedQueryPagination(state)(props.cacheKey),
  accounts: selectAccounts(state)
}))
