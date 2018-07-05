import { createFetcher } from '../utils/createFetcher'
import { getWallets } from './action'
import {
  selectWalletsCachedQuery,
  selectWalletsCachedQueryPagination
} from './selector'
export default createFetcher('all_wallets', getWallets, (state, props) => ({
  data: selectWalletsCachedQuery(state)(props.cacheKey),
  pagination: selectWalletsCachedQueryPagination(state)(props.cacheKey)
}))
