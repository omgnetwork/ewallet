import { createFetcher } from '../utils/createFetcher'
import { getWalletsByAccountId, getWalletsByUserId } from './action'
import {
  selectWalletsLoadingStatus,
  selectWalletsCachedQuery,
  selectWalletsCachedQueryPagination
} from './selector'

export default createFetcher(
  'wallets',
  getWalletsByAccountId,
  (state, props) => ({
    loadingStatus: selectWalletsLoadingStatus(state),
    data: selectWalletsCachedQuery(state)(props.cacheKey),
    pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
  })
)

export const UserWalletsFetcher = createFetcher(
  'user_wallets',
  getWalletsByUserId,
  (state, props) => ({
    loadingStatus: selectWalletsLoadingStatus(state),
    data: selectWalletsCachedQuery(state)(props.cacheKey),
    pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
  })
)
