import { createFetcher } from '../utils/createFetcher'
import { getListMembers } from './action'
import { selectInviteListLoadingStatus, selectInvitesCachedQuery, selectInvitesCachedQueryPagination } from './selector'
export default createFetcher('inviteLists', getListMembers, (state, props) => ({
  loadingStatus: selectInviteListLoadingStatus(state),
  data: selectInvitesCachedQuery(state)(props.cacheKey),
  pagination: selectInvitesCachedQueryPagination(state)(props.cacheKey)
}))
 