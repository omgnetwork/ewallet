import { createFetcher } from '../utils/createFetcher'
import { getUsers } from './action'
import { selectUsersLoadingStatus, selectUsersAllPagesCachedQuery, selectUsersCachedQueryPagination } from './selector'
export default createFetcher('users', getUsers, (state, props) => ({
  loadingStatus: selectUsersLoadingStatus(state),
  data: selectUsersAllPagesCachedQuery(state)(props.cacheKey),
  pagination: selectUsersCachedQueryPagination(state)(props.cacheKey)
}))
