export const selectTokens = (state, search) => {
  return _.values(state.tokens)
  .filter(x => {
    const reg = new RegExp(search)
    return reg.test(x.name) || reg.test(x.symbol)
  })
}
export const selectTokensCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(tokenId => {
    return selectGetTokenById(state)(tokenId)
  })
}
export const selectTokensCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
export const selectTokensLoadingStatus = state => state.tokensLoadingStatus
export const selectGetTokenById = state => id => state.tokens[id]
