import { createFetcher } from '../utils/createFetcher'
import { getWalletsByAccountId } from './action'
import {
  selectWalletsLoadingStatus,
  selectWalletsAllPagesCachedQuery,
  selectWalletsCachedQueryPagination
} from './selector'
export default createFetcher('wallets', getWalletsByAccountId, (state, props) => ({
  loadingStatus: selectWalletsLoadingStatus(state),
  data: selectWalletsAllPagesCachedQuery(state)(props.cacheKey),
  pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
}))
