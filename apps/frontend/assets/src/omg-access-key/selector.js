export const selectAccessKeysLoadingStatus = state =>
  state.loadingStatus.accessKeys

export const selectGetAccessKeyById = state => id => state.accessKeys[id]

export const selectAccessKeysCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(apiKeyId => {
    return selectGetAccessKeyById(state)(apiKeyId)
  })
}

export const selectAccessKeyMemberships = state => id =>
  state.accessKeyMemberships[id]
export const selectAccessKeyMembershipsLoadingStatus = state =>
  state.loadingStatus.accessKeyMemberships || 'DEFAULT'
