export const selectMetamaskEnabled = state =>
  !!state.metamask.unlocked && !!state.metamask.enabled
export const selectCurrentAddress = state => state.metamask.selectedAddress
export const selectBlockchainBalanceByAddress = state => address =>
  _.values(state.blockchainBalance[address])
