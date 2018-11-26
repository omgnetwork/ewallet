export const selectInviteList = state => _.values(state.inviteList)
export const selectInviteById = state => id => state.inviteList[id] || {}
export const selectInviteListLoadingStatus = state => state.inviteListLoadingStatus

export const selectInvitesCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(inviteId => {
    return selectInviteById(state)(inviteId)
  })
}

export const selectInvitesCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
