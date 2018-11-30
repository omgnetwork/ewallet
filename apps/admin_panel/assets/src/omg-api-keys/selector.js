export const selectApiKeys = state => _.sortBy(_.values(state.apiKeys), 'created_at').reverse()
export const selectApiKeysLoadingStatus = state => state.loadingStatus.apiKeys
export const selectGetApiKeyById = state => id => state.apiKeys[id]

export const selectApiKeysCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(apiKeyId => {
    return selectGetApiKeyById(state)(apiKeyId)
  })
}
