import { createFetcher } from '../utils/createFetcher'
import { getActivityLogs } from './action'
import { selectActivitiesLoadingStatus, selectActivitiesCachedQuery, selectActivites } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('activity', getActivityLogs, (state, props) => ({
  loadingStatus: selectActivitiesLoadingStatus(state),
  data: selectActivitiesCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey),
  activities: selectActivites(state)
}))
