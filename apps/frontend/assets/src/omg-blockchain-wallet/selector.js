export const selectBlockchainWallets = state => {
  return _.values(state.blockchainWallets) || []
}

export const selectBlockchainWalletBalance = state => address => {
  return state.blockchainWalletBalance[address] || []
}
export const selectBlockchainWalletBalanceCachedQuery = state => address => {
  return state.blockchainWalletBalance[address] || []
}

export const selectBlockchainWalletsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(id => {
    return selectBlockchainWalletById(state)(id)
  })
}
export const selectBlockchainWalletById = state => id => state.blockchainWallets[id] || {}

export const selectBlockchainWalletsLoadingStatus = state => state.loadingStatus.blockchainWallets
