import { createFetcher } from '../utils/createFetcher'
import { getUsers } from './action'
import { selectUsersLoadingStatus, selectUsersCachedQuery, selectUsersCachedQueryPagination } from './selector'
export default createFetcher('users', getUsers, (state, props) => ({
  loadingStatus: selectUsersLoadingStatus(state),
  data: selectUsersCachedQuery(state)(props.cacheKey),
  pagination: selectUsersCachedQueryPagination(state)(props.cacheKey)
}))
