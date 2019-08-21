import { createFetcher } from '../utils/createFetcher'
import { getAllBlockchainWallets, getBlockchainWalletBalance } from './action'
import {
  selectBlockchainWalletsLoadingStatus,
  selectBlockchainWalletsCachedQuery,
  selectBlockchainWalletBalance,
  selectBlockchainWallets
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'

export const AllBlockchainWalletsFetcher = createFetcher('blockchainwallets', getAllBlockchainWallets, (state, props) => ({
  loadingStatus: selectBlockchainWalletsLoadingStatus(state),
  data: selectBlockchainWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  blockchainWallets: selectBlockchainWallets(state)
}))

export const BlockchainWalletBalanceFetcher = createFetcher('blockchainwalletbalance', getBlockchainWalletBalance, (state, props) => {
  return {
    loadingStatus: selectBlockchainWalletsLoadingStatus(state),
    pagination: selectCachedQueryPagination(state)(props.cacheKey),
    data: selectBlockchainWalletBalance(state)(props.query.address)
  }
})
