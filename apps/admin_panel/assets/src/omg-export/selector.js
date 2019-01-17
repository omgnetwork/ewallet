export const selectExports = state => {
  return _.values(state.exports)
}

export const selectExportsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(exportId => {
    return selectGetExportById(state)(exportId)
  })
}

export const selectGetExportById = state => id => state.exports[id] || {}

export const selectExportsLoadingStatus = state => state.loadingStatus.exports

