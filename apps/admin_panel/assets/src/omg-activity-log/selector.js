export const selectActivites = state => {
  return _.values(state.activities) || []
}

export const selectActivitiesCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(activityId => {
    return selectGetActivityById(state)(activityId)
  })
}
export const selectGetActivityById = state => id => state.activities[id] || {}

export const selectActivitiesCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}

export const selectActivitiesLoadingStatus = state => state.loadingStatus.activities
