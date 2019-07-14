export const selectMetamaskEnabled = state =>
  !!state.metamask.unlocked && !!state.metamask.enabled
export const selectCurrentAddress = state => state.metamask.selectedAddress
export const selectBlockchainBalanceByAddressArray = state => address =>
  _.values(selectBlockchainBalanceByAddress(state)(address))

export const selectBlockchainBalanceByAddress = state => address =>
  state.blockchainBalance[address]
