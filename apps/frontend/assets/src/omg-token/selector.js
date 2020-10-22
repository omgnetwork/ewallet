import _ from 'lodash'
import { createSelectAllPagesCachedQuery } from '../omg-cache/selector'

export const selectTokens = (state, search) => {
  return _.values(state.tokens)
    .filter(x => {
      const reg = new RegExp(search)
      return reg.test(x.name) || reg.test(x.symbol)
    })
}
export const selectBlockchainTokenByAddress = state => blockchainAddress => {
  const tokenKey = _.findKey(state.tokens, ['blockchain_address', blockchainAddress])
  return state.tokens[tokenKey]
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

export const selectTokensLoadingStatus = state => state.loadingStatus.tokens
export const selectGetTokenById = state => id => {
  return state.tokens[id]
}
export const selectTokenCapabilitiesById = state => id => {
  const token = state.tokens[id]
  if (token) {
    return state.tokenCapabilities[token.blockchain_address]
  }
}
export const selectGetMintedTokenHistryById = state => id => {
  return state.mintedTokenHistory[id]
}

export const selectTokensAllPagesCachedQuery = createSelectAllPagesCachedQuery(
  selectGetTokenById
)
