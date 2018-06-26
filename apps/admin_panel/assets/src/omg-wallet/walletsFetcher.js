import { createFetcher } from '../utils/createFetcher'
import { getWalletsByAccountId } from './action'
import {
  selectWalletsLoadingStatus,
  selectWalletsCachedQuery,
  selectWalletsCachedQueryPagination
} from './selector'
export default createFetcher(getWalletsByAccountId, (state, props) => ({
  loadingStatus: selectWalletsLoadingStatus(state),
  data: selectWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
}))
