import { createFetcher } from '../utils/createFetcher'
import { getAllBlockchainWallets, getBlockchainWalletBalance } from './action'
import {
  selectBlockchainWalletsLoadingStatus,
  selectBlockchainWalletsCachedQuery,
  selectBlockchainWallets
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'

export const AllBlockchainWalletsFetcher = createFetcher('blockchainwallets', getAllBlockchainWallets, (state, props) => ({
  loadingStatus: selectBlockchainWalletsLoadingStatus(state),
  data: selectBlockchainWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  blockchainWallets: selectBlockchainWallets(state)
}))

export const BlockchainWalletBalanceFetcher = createFetcher('blockchainwalletbalance', getBlockchainWalletBalance, (state, props) => ({
  loadingStatus: selectBlockchainWalletsLoadingStatus(state),
  data: selectBlockchainWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  blockchainWallets: selectBlockchainWallets(state)
}))
