import { createFetcher } from '../utils/createFetcher'
import { getAdmins } from './action'
import { selectAdminsLoadingStatus, selectAdminsCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('admins', getAdmins, (state, props) => ({
  loadingStatus: selectAdminsLoadingStatus(state),
  data: selectAdminsCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
