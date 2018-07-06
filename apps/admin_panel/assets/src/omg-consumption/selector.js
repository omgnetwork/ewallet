import { createSelectAllPagesCachedQuery } from '../omg-cache/selector'
export const selectConsumptions = state => {
  return _.values(state.consumptions) || []
}
export const selectPendingConsumptions = transactionRequestId => state => {
  return (
    _
      .sortBy(
        selectConsumptions(state).filter(
          t => t.status === 'pending' && t.transaction_request.id === transactionRequestId
        ),
        'created_date'
      )
      .reverse() || []
  )
}
export const selectConsumptionsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(id => {
    return selectGetConsumptionById(state)(id)
  })
}
export const selectNewConsumptions = state => {
  return selectConsumptions(state).filter(t => t.new) || []
}

export const selectGetConsumptionById = state => id => state.consumptions[id] || {}

export const selectConsumptionsAllPagesCachedQuery = createSelectAllPagesCachedQuery(
  selectGetConsumptionById
)
export const selectConsumptionsLoadingStatus = state => state.consumptionsLoadingStatus
