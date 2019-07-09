export const selectConsumptions = state => {
  return _.values(state.consumptions) || []
}

export const selectConsumptionsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(id => {
    return selectGetConsumptionById(state)(id)
  })
}

export const selectGetConsumptionById = state => id => state.consumptions[id] || {}

export const selectConsumptionsLoadingStatus = state => state.loadingStatus.consumptions
