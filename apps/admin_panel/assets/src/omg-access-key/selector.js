export const selectAccessKeys = state => _.sortBy(_.values(state.accessKeyss), 'created_at').reverse()
export const selectAccessKeysLoadingStatus = state => state.AccessKeysLoadingStatus

export const selectGetAccessKeyById = state => id => state.accessKeys[id]

export const selectAccessKeysCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(apiKeyId => {
    return selectGetAccessKeyById(state)(apiKeyId)
  })
}
