export const selectExchangePairs = state => {
  return _.values(state.exchangePair)
}

export const selectExchangePairsByFromTokenId = state => fromTokenId => {
  return _.values(state.exchangePair).filter(e => e.frokTokenId === fromTokenId)
}

export const selectExchangePairCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(exchangePairId => {
    return selectExchangePairById(state)(exchangePairId)
  })
}

export const selectExchangePairCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}

export const selectExchangePairById = state => id => state.exchangePairs[id]
