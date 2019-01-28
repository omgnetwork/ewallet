import { createFetcher } from '../utils/createFetcher'
import { getWallets } from './action'
import {
  selectWalletsLoadingStatus,
  selectWalletsCachedQuery,
  selectWalletsCachedQueryPagination
} from './selector'
export default createFetcher('account_users_wallets', getWallets, (state, props) => ({
  loadingStatus: selectWalletsLoadingStatus(state),
  data: selectWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
}))
