import { createSelectAllPagesCachedQuery } from '../omg-cache/selector'
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
export const selectMintedTokenHistoryCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(mintedTokenHistoryId => {
    return selectGetMintedTokenHistryById(state)(mintedTokenHistoryId)
  })
}

export const selectTokensLoadingStatus = state => state.loadingStatus.TOKENS
export const selectGetTokenById = state => id => {
  return state.tokens[id]
}
export const selectGetMintedTokenHistryById = state => id => {
  return state.mintedTokenHistory[id]
}

export const selectTokensAllPagesCachedQuery = createSelectAllPagesCachedQuery(
  selectGetTokenById
)
