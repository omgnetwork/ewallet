import { createFetcher } from '../utils/createFetcher'
import { getWalletsAndUserWalletsByAccountId } from './action'
import {
  selectWalletsLoadingStatus,
  selectWalletsCachedQuery,
  selectWalletsCachedQueryPagination
} from './selector'
export default createFetcher('account_users_wallets', getWalletsAndUserWalletsByAccountId, (state, props) => ({
  loadingStatus: selectWalletsLoadingStatus(state),
  data: selectWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
}))
