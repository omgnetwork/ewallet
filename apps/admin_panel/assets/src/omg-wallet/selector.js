import { createSelectAllPagesCachedQuery } from '../omg-cache/selector'
export const selectWallets = (state, search) => {
  return _.values(state.wallets).filter(wallet => {
    const reg = new RegExp(search)
    return reg.test(wallet.name) || reg.test(wallet.address)
  })
}
export const selectWalletsByAccountId = (state, search, accountId) => {
  return _.values(state.wallets).filter(wallet => {
    const reg = new RegExp(search)
    return wallet.account_id === accountId && (reg.test(wallet.name) || reg.test(wallet.address))
  })
}
export const selectWalletsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(tokenId => {
    return selectWalletById(tokenId)(state)
  })
}
export const selectWalletsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
export const selectWalletsLoadingStatus = state => state.walletsLoadingStatus
export const selectWalletById = id => state => state.wallets[id]
export const selectWalletByUserId = userId => state => {
  return _.values(state.wallets).find(wallet => {
    return wallet.user_id === userId
  })
}

export const selectWalletsAllPagesCachedQuery = createSelectAllPagesCachedQuery(
  selectWalletById
)
