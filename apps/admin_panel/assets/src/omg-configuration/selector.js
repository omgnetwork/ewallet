export const selectConfigurationById = state => configurationId => {
  return state.configurations[configurationId] || {}
}

export const selectConfigurationsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(configurationId => {
    return selectConfigurationById(state)(configurationId)
  })
}

export const selectConfigurationsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
