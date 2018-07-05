import { createFetcher } from '../utils/createFetcher'
import { getConsumptions } from './action'
import {
  selectConsumptionsLoadingStatus,
  selectConsumptionsCachedQuery,
  selectConsumptions
} from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('consumptions', getConsumptions, (state, props) => ({
  loadingStatus: selectConsumptionsLoadingStatus(state),
  data: selectConsumptionsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  consumptions: selectConsumptions(state)
}))
