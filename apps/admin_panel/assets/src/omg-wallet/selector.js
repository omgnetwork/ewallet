export const selectWallets = (state, search) => {
  return _.values(state.wallets)
  .filter(x => {
    const reg = new RegExp(search)
    return reg.test(x.name) || reg.test(x.address)
  })
}
export const selectWalletsLoadingStatus = state => state.walletsLoadingStatus
export const selectWalletById = id => state => state.wallets[id]
