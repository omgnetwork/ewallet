import { createFetcher } from '../utils/createFetcher'
import { getListMembers } from './action'
import { selectInviteListLoadingStatus, selectInvitesCachedQuery } from './selector'
import { selectCachedQueryPagination } from '../omg-cache/selector'
export default createFetcher('inviteLists', getListMembers, (state, props) => ({
  loadingStatus: selectInviteListLoadingStatus(state),
  data: selectInvitesCachedQuery(state)(props.cacheKey),
  pagination: selectCachedQueryPagination(state)(props.cacheKey)
}))
