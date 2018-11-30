export const selectConfigurationById = state => configurationId => {
  return state.configurations[configurationId] || {}
}

export const selectConfigurations = state => {
  return state.configurations || {}
}

export const selectConfigurationsByKey = state => {
  return _.keyBy(selectConfigurations(state), 'key')
}

export const selectConfigurationsCachedQuery = state => cacheKey => {
  return _.chain(state.cacheQueries[cacheKey])
    .get('ids', [])
    .map(configurationId => {
      return selectConfigurationById(state)(configurationId)
    })
    .keyBy('key')
    .value()
}

export const selectConfigurationsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}

export const selectConfigurationLoadingStatus = state => state.loadingStatus.configurations
