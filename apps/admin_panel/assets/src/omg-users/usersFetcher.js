import { createFetcher } from '../utils/createFetcher'
import * as accountActions from '../omg-account/action'
import {
  selectUsersLoadingStatus,
  selectUsersCachedQuery,
  selectUsersCachedQueryPagination
} from './selector'
export default createFetcher('users', accountActions.getUsers, (state, props) => ({
  loadingStatus: selectUsersLoadingStatus(state),
  data: selectUsersCachedQuery(state)(props.cacheKey),
  pagination: selectUsersCachedQueryPagination(state)(props.cacheKey)
}))

export const getUsersByAccountId = createFetcher(
  'users_account',
  accountActions.getUsersByAccountId,
  (state, props) => ({
    loadingStatus: selectUsersLoadingStatus(state),
    data: selectUsersCachedQuery(state)(props.cacheKey),
    pagination: selectUsersCachedQueryPagination(state)(props.cacheKey)
  })
)
