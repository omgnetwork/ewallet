import { createFetcher } from '../utils/createFetcher'
import { getAllBlockchainWallets } from './action'
import {
  selectConsumptionsLoadingStatus,
  selectConsumptionsCachedQuery,
  selectConsumptions
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'

export default createFetcher('blockchainwallets', getAllBlockchainWallets, (state, props) => ({
  loadingStatus: selectConsumptionsLoadingStatus(state),
  data: selectConsumptionsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  consumptions: selectConsumptions(state)
}))
